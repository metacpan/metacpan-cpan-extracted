#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Errno qw(EINTR);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use FindBin qw($Bin);
use Getopt::Long qw(GetOptions);
use IO::Select;
use IO::Socket::INET;
use JSON::PP ();
use POSIX qw(WNOHANG strftime uname);
use Time::HiRes qw(time sleep);

$SIG{PIPE} = 'IGNORE';

my $go_binary = "/tmp/le-http-bench-go-$$";
my $h2o_binary = "/tmp/le-http-bench-libh2o-$$";
END {
    unlink $go_binary if -e $go_binary;
    unlink $h2o_binary if -e $h2o_binary;
}

my %server = (
    linuxevent => {
        label => 'Linux::Event::HTTP',
        command => [$^X, '-Mblib', "$Bin/servers/linuxevent-http.pl"],
        available => sub { 1 },
    },
    feersum => {
        label => 'Feersum',
        command => [$^X, "$Bin/servers/feersum-http.pl"],
        available => sub { command_ok($^X, '-MFeersum', '-e', '1') },
    },
    mojo => {
        label => 'Mojolicious',
        command => [$^X, "$Bin/servers/mojo-http.pl"],
        available => sub { command_ok($^X, '-MMojolicious', '-e', '1') },
    },
    twiggy => {
        label => 'Twiggy/AnyEvent',
        command => [$^X, "$Bin/servers/twiggy-http.pl"],
        available => sub { command_ok($^X, '-MTwiggy', '-e', '1') },
    },
    node => {
        label => 'Node.js http',
        command => ['node', "$Bin/servers/node-http.js"],
        available => sub { command_ok('node', '--version') },
    },
    go => {
        label => 'Go net/http',
        command => [$go_binary],
        available => sub { command_ok('go', 'version') },
        prepare => sub {
            system 'go', 'build', '-o', $go_binary, "$Bin/servers/go-http.go";
            die "failed to build Go benchmark server\n" if $? != 0;
        },
    },
    h2o => {
        label => 'libh2o evloop',
        command => [$h2o_binary],
        available => sub {
            command_ok('cc', '--version')
                && command_ok('pkg-config', '--exists', 'libh2o-evloop');
        },
        prepare => sub {
            my $flags = capture(
                'pkg-config', '--cflags', '--libs', 'libh2o-evloop',
            );
            die "failed to query libh2o-evloop build flags\n"
                if !defined $flags;
            my @flags = grep { length } split /\s+/, $flags;
            system 'cc', '-O2', '-o', $h2o_binary,
                "$Bin/servers/libh2o-http.c", @flags;
            die "failed to build libh2o benchmark server\n" if $? != 0;
        },
    },
    aiohttp => {
        label => 'Python aiohttp',
        command => ['python3', "$Bin/servers/aiohttp-http.py"],
        available => sub { command_ok('python3', '-c', 'import aiohttp') },
    },
);

# Twiggy remains available explicitly, but is not in the primary comparison
# because current Twiggy closes the long-lived benchmark connections before the
# requested keep-alive workload completes. libh2o is also explicit-only because
# it is an architecture experiment, not a project dependency.
my @servers = qw(linuxevent feersum mojo node go aiohttp);
my $requests = 20_000;
my $warmup = 2_000;
my $connections = 100;
my $pipeline = 1;
my $request_body_bytes = 0;
my $response_bytes = 32;
my $repeats = 5;
my $timeout = 120;
my $strict = 0;
my $smoke = 0;
my $json_path;
my $help = 0;

GetOptions(
    'servers=s'            => sub { @servers = split /,/, $_[1] },
    'requests=i'           => \$requests,
    'warmup=i'             => \$warmup,
    'connections=i'        => \$connections,
    'pipeline=i'           => \$pipeline,
    'request-body-bytes=i' => \$request_body_bytes,
    'response-bytes=i'     => \$response_bytes,
    'repeats=i'            => \$repeats,
    'timeout=f'            => \$timeout,
    'strict!'              => \$strict,
    'smoke'                => \$smoke,
    'json=s'               => \$json_path,
    'help'                 => \$help,
) or usage(2);

usage(0) if $help;
if ($smoke) {
    $requests = 500;
    $warmup = 100;
    $connections = 4;
    $pipeline = 1;
    $response_bytes = 8;
    $repeats = 1;
    $timeout = 15;
}

die "requests must be > 0\n" if $requests <= 0;
die "warmup must be >= 0\n" if $warmup < 0;
die "connections must be > 0\n" if $connections <= 0;
die "pipeline must be > 0\n" if $pipeline <= 0;
die "request-body-bytes must be >= 0\n" if $request_body_bytes < 0;
die "response-bytes must be >= 0\n" if $response_bytes < 0;
die "repeats must be > 0\n" if $repeats <= 0;
die "timeout must be > 0\n" if $timeout <= 0;
die "at least one server is required\n" if !@servers;
die "unknown server: $_\n" for grep { !exists $server{$_} } @servers;

my (@available, @skipped);
for my $name (@servers) {
    if ($server{$name}{available}->()) {
        push @available, $name;
    } else {
        push @skipped, $name;
    }
}
if (@skipped && $strict) {
    die "unavailable benchmark servers: " . join(', ', @skipped) . "\n";
}
die "no requested benchmark servers are available\n" if !@available;

for my $name (@available) {
    $server{$name}{prepare}->() if $server{$name}{prepare};
}

my $request_wire = make_request($request_body_bytes);
my @records;

say 'Linux::Event::HTTP cross-server comparison';
say 'servers=' . join(',', @available);
say 'skipped=' . join(',', @skipped) if @skipped;
say "requests=$requests warmup=$warmup connections=$connections pipeline=$pipeline request_body_bytes=$request_body_bytes response_bytes=$response_bytes repeats=$repeats";
say 'mode=single-process single-execution-slot loopback-tcp shared-client';

for my $repeat (1 .. $repeats) {
    for my $name (rotated_servers($repeat, @available)) {
        my $row = run_case($name, $request_wire);
        $row->{repeat} = $repeat;
        push @records, $row;
        printf "%-24s repeat=%d %10.1f req/s p50=%8.1f us p95=%8.1f us p99=%8.1f us max=%8.1f us\n",
            $server{$name}{label}, $repeat,
            @{$row}{qw(requests_per_second latency_us_p50 latency_us_p95 latency_us_p99 latency_us_max)};
    }
}

my @summary;
say '';
say 'Median comparison';
printf "%-24s %12s %12s %12s %12s %12s\n",
    'server', 'req/s', 'p50 us', 'p95 us', 'p99 us', 'max us';
for my $name (@available) {
    my @set = grep { $_->{server} eq $name } @records;
    my $row = {
        server => $name,
        label => $server{$name}{label},
        requests_per_second => median(map { $_->{requests_per_second} } @set),
        latency_us_p50 => median(map { $_->{latency_us_p50} } @set),
        latency_us_p95 => median(map { $_->{latency_us_p95} } @set),
        latency_us_p99 => median(map { $_->{latency_us_p99} } @set),
        latency_us_max => median(map { $_->{latency_us_max} } @set),
    };
    push @summary, $row;
    printf "%-24s %12.1f %12.1f %12.1f %12.1f %12.1f\n",
        $row->{label},
        @{$row}{qw(requests_per_second latency_us_p50 latency_us_p95 latency_us_p99 latency_us_max)};
}

if (defined $json_path) {
    my ($sysname, $nodename, $release, $version, $machine) = uname();
    my $report = {
        benchmark => 'linux-event-http-cross-server',
        benchmark_contract_version => 2,
        generated_at => strftime('%Y-%m-%dT%H:%M:%SZ', gmtime),
        environment => {
            perl => "$^V",
            feersum => capture($^X, '-MFeersum', '-e', 'print $Feersum::VERSION'),
            mojolicious => capture($^X, '-MMojolicious', '-e', 'print $Mojolicious::VERSION'),
            twiggy => capture($^X, '-MTwiggy', '-e', 'print $Twiggy::VERSION'),
            node => capture('node', '--version'),
            go => capture('go', 'version'),
            libh2o_evloop => capture('pkg-config', '--modversion', 'libh2o-evloop'),
            python => capture('python3', '--version'),
            aiohttp => capture('python3', '-c', 'import aiohttp; print(aiohttp.__version__)'),
            os => $sysname,
            kernel => $release,
            machine => $machine,
        },
        configuration => {
            servers => \@available,
            skipped => \@skipped,
            requests => $requests,
            warmup => $warmup,
            connections => $connections,
            pipeline => $pipeline,
            request_body_bytes => $request_body_bytes,
            response_bytes => $response_bytes,
            repeats => $repeats,
            timeout => $timeout,
        },
        summary => \@summary,
        records => \@records,
    };
    my $dir = dirname($json_path);
    make_path($dir) if $dir ne '.' && !-d $dir;
    open my $fh, '>', $json_path or die "open $json_path: $!\n";
    print {$fh} JSON::PP->new->canonical->pretty->encode($report);
    close $fh or die "close $json_path: $!\n";
    say "json=$json_path";
}

sub run_case ($name, $wire) {
    my $port = free_port();
    my ($pid, $stdout_path, $stderr_path) = start_server($name, $port);
    wait_ready($name, $pid, $port, $stdout_path, $stderr_path);

    my (@socket, $latency, $wall);
    my $ok = eval {
        @socket = open_clients($port, $connections);
        drive_phase(\@socket, $wire, $warmup, $pipeline, 0, $timeout)
            if $warmup;
        my $start = time;
        $latency = drive_phase(
            \@socket, $wire, $requests, $pipeline, 1, $timeout,
        );
        $wall = time - $start;
        1;
    };
    my $error = $@;

    close $_ for @socket;
    stop_server($pid);

    if (!$ok) {
        my $detail = slurp_log('stdout', $stdout_path)
            . slurp_log('stderr', $stderr_path);
        unlink $stdout_path;
        unlink $stderr_path;
        die "$server{$name}{label} failed: $error$detail";
    }

    unlink $stdout_path;
    unlink $stderr_path;
    return {
        server => $name,
        requests => $requests,
        wall_seconds => $wall,
        requests_per_second => $requests / $wall,
        latency_us_p50 => percentile_us($latency, 50),
        latency_us_p95 => percentile_us($latency, 95),
        latency_us_p99 => percentile_us($latency, 99),
        latency_us_max => max_us($latency),
    };
}

sub start_server ($name, $port) {
    my $stdout_path = "/tmp/le-http-bench-$name-$$-out.log";
    my $stderr_path = "/tmp/le-http-bench-$name-$$-err.log";
    my $pid = fork();
    die "fork $name: $!\n" if !defined $pid;

    if ($pid == 0) {
        $ENV{BENCH_PORT} = $port;
        $ENV{BENCH_RESPONSE_BYTES} = $response_bytes;
        open STDOUT, '>', $stdout_path or POSIX::_exit(126);
        open STDERR, '>', $stderr_path or POSIX::_exit(126);
        child_exec(@{$server{$name}{command}});
        POSIX::_exit(127);
    }
    return ($pid, $stdout_path, $stderr_path);
}

sub wait_ready ($name, $pid, $port, $stdout_path, $stderr_path) {
    my $deadline = time + $timeout;
    while (time < $deadline) {
        my $fh = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto => 'tcp',
            Timeout => 0.1,
        );
        if ($fh) {
            close $fh;
            return;
        }
        my $done = waitpid($pid, WNOHANG);
        die server_failure($name, $stdout_path, $stderr_path)
            if $done == $pid;
        sleep 0.01;
    }
    stop_server($pid);
    die "benchmark server $name did not listen on port $port\n"
        . slurp_log('stdout', $stdout_path)
        . slurp_log('stderr', $stderr_path);
}

sub server_failure ($name, $stdout_path, $stderr_path) {
    return "benchmark server $name exited before becoming ready\n"
        . slurp_log('stdout', $stdout_path)
        . slurp_log('stderr', $stderr_path);
}

sub slurp_log ($label, $path) {
    return '' if !-e $path;
    open my $fh, '<', $path or return '';
    local $/;
    my $text = <$fh> // '';
    close $fh;
    return $text eq '' ? '' : "$label:\n$text\n";
}

sub stop_server ($pid) {
    return if !defined $pid || $pid <= 0;
    kill 'TERM', $pid;
    my $deadline = time + 1;
    while (time < $deadline) {
        my $done = waitpid($pid, WNOHANG);
        return if $done == $pid || $done == -1;
        sleep 0.01;
    }
    kill 'KILL', $pid;
    waitpid($pid, 0);
}

sub free_port () {
    my $fh = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto => 'tcp',
        Listen => 1,
        ReuseAddr => 1,
    ) or die "allocate benchmark port: $!\n";
    my $port = $fh->sockport;
    close $fh;
    return $port;
}

sub open_clients ($port, $count) {
    my @socket;
    for (1 .. $count) {
        my $fh = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto => 'tcp',
        ) or die "connect 127.0.0.1:$port: $!\n";
        $fh->autoflush(1);
        push @socket, $fh;
    }
    return @socket;
}

sub drive_phase ($socket, $wire, $count, $depth, $measure, $phase_timeout) {
    return [] if $count == 0;

    my $select = IO::Select->new;
    my %state;
    my $base = int($count / @$socket);
    my $extra = $count % @$socket;
    for my $i (0 .. $#$socket) {
        my $quota = $base + ($i < $extra ? 1 : 0);
        next if !$quota;
        my $fh = $socket->[$i];
        $state{fileno($fh)} = {
            fh => $fh,
            quota => $quota,
            sent => 0,
            received => 0,
            buffer => '',
            sent_at => [],
        };
        $select->add($fh);
    }

    my @latency;
    my $received = 0;
    my $deadline = time + $phase_timeout;
    fill_pipeline($_, $wire, $depth, $measure) for values %state;

    while ($received < $count) {
        my $remaining = $deadline - time;
        die "benchmark client timed out after $phase_timeout seconds\n"
            if $remaining <= 0;
        my @ready = $select->can_read($remaining);
        die "benchmark client timed out after $phase_timeout seconds\n"
            if !@ready;

        for my $fh (@ready) {
            my $s = $state{fileno($fh)} or next;
            my $chunk = '';
            my $n = sysread($fh, $chunk, 65_536);
            if (!defined $n) {
                next if $! == EINTR;
                die "client read failed: $!\n";
            }
            die "server closed connection before benchmark phase completed\n"
                if $n == 0;
            $s->{buffer} .= $chunk;

            while (1) {
                my $head_end = index($s->{buffer}, "\r\n\r\n");
                last if $head_end < 0;
                my $head_len = $head_end + 4;
                my $head = substr($s->{buffer}, 0, $head_len);
                die "benchmark response was not HTTP 200\n"
                    if $head !~ /\AHTTP\/1\.[01] 200\b/;
                die "benchmark response missing Content-Length\n"
                    if $head !~ /\r\nContent-Length:\s*(\d+)\r\n/i;
                my $body_len = 0 + $1;
                last if length($s->{buffer}) < $head_len + $body_len;

                substr($s->{buffer}, 0, $head_len + $body_len, '');
                ++$s->{received};
                ++$received;
                if ($measure) {
                    my $sent_at = shift @{$s->{sent_at}};
                    push @latency, time - $sent_at;
                }
                fill_pipeline($s, $wire, $depth, $measure);
            }
        }
    }
    return \@latency;
}

sub fill_pipeline ($state, $wire, $depth, $measure) {
    while ($state->{sent} < $state->{quota}
        && $state->{sent} - $state->{received} < $depth) {
        write_all($state->{fh}, $wire);
        push @{$state->{sent_at}}, time if $measure;
        ++$state->{sent};
    }
}

sub write_all ($fh, $bytes) {
    my $offset = 0;
    while ($offset < length($bytes)) {
        my $n = syswrite($fh, $bytes, length($bytes) - $offset, $offset);
        if (!defined $n) {
            next if $! == EINTR;
            die "client write failed: $!\n";
        }
        die "client write returned zero bytes\n" if $n == 0;
        $offset += $n;
    }
}

sub make_request ($body_bytes) {
    my $body = 'b' x $body_bytes;
    return $body_bytes
        ? "POST /bench HTTP/1.1\r\nHost: benchmark.test\r\nContent-Length: $body_bytes\r\nContent-Type: application/octet-stream\r\n\r\n$body"
        : "GET /bench HTTP/1.1\r\nHost: benchmark.test\r\n\r\n";
}

sub percentile_us ($values, $percent) {
    return 0 if !@$values;
    my @sorted = sort { $a <=> $b } @$values;
    my $index = int(($percent * @sorted + 99) / 100) - 1;
    $index = 0 if $index < 0;
    $index = $#sorted if $index > $#sorted;
    return $sorted[$index] * 1_000_000;
}

sub max_us ($values) {
    return 0 if !@$values;
    my $max = 0;
    for my $value (@$values) {
        $max = $value if $value > $max;
    }
    return $max * 1_000_000;
}

sub median (@values) {
    return 0 if !@values;
    @values = sort { $a <=> $b } @values;
    my $mid = int(@values / 2);
    return @values % 2
        ? $values[$mid]
        : ($values[$mid - 1] + $values[$mid]) / 2;
}

sub rotated_servers ($repeat, @list) {
    return @list if @list < 2;
    my $offset = ($repeat - 1) % @list;
    return (@list[$offset .. $#list], @list[0 .. $offset - 1]);
}

sub child_exec (@command) {
    exec @command;
}

sub command_ok (@command) {
    my $pid = fork();
    return 0 if !defined $pid;
    if ($pid == 0) {
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        child_exec(@command);
        POSIX::_exit(127);
    }
    waitpid($pid, 0);
    return $? == 0;
}

sub capture (@command) {
    pipe(my $read, my $write) or return undef;
    my $pid = fork();
    if (!defined $pid) {
        close $read;
        close $write;
        return undef;
    }
    if ($pid == 0) {
        close $read;
        open STDOUT, '>&', $write or POSIX::_exit(126);
        open STDERR, '>', '/dev/null';
        close $write;
        child_exec(@command);
        POSIX::_exit(127);
    }

    close $write;
    local $/;
    my $text = <$read> // '';
    close $read;
    waitpid($pid, 0);
    return undef if $? != 0;
    $text =~ s/\A\s+//;
    $text =~ s/\s+\z//;
    return $text;
}

sub usage ($status) {
    print <<'USAGE';
usage: bench/run-http-comparison.pl [options]

  --servers=LIST           linuxevent,feersum,mojo,twiggy,node,go,h2o,aiohttp
  --requests=N             measured requests per server/repeat (default 20000)
  --warmup=N               warmup requests per server/repeat (default 2000)
  --connections=N          concurrent TCP connections (default 100)
  --pipeline=N             max outstanding requests per connection (default 1)
  --request-body-bytes=N   fixed request body bytes (default 0)
  --response-bytes=N       fixed response body bytes (default 32)
  --repeats=N              rotated benchmark repeats (default 5)
  --timeout=SECONDS        server/client phase timeout (default 120)
  --strict                 fail instead of skipping unavailable competitors
  --json=PATH              write machine-readable report
  --smoke                  tiny keep-alive correctness workload
  --help                   show this help
USAGE
    exit $status;
}
