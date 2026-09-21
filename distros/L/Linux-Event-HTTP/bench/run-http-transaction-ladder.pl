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
use POSIX qw(strftime uname);
use POSIX ();
use Time::HiRes qw(time sleep);

$SIG{PIPE} = 'IGNORE';

my %case = (
    current_http => {
        label => 'C full Server + Content-Type',
        command => [$^X, '-Mblib', "$Bin/servers/linuxevent-http.pl"],
        linuxevent_mode => 'content-type',
        description => 'Current Server plus production native Server::Connection lifecycle with ordinary Content-Type scalar response',
    },
);

# Contract 10: keep manual construction diagnostics separate from the
# production native-input Connection.
my @production_stages = (
    [prod_api => 'P1 parse + public Response mutation + prebuilt write',
        'Manual byte driver: native Request parse, compact Response, public Content-Type/body setters, and prebuilt wire'],
    [prod_wire => 'P2 + production native scalar wire builder',
        'P1 plus build_simple_scalar_final validation, generated Content-Length metadata, commit, and wire construction'],
    [prod_active => 'P3 + minimal active exchange fields',
        'P2 plus assignment and retirement of the three live exchange fields used by the production Connection'],
    [prod_connection => 'P4 production native Connection',
        'Actual Server::Connection with inherited native HTTP input through a raw Listener; no copied HTTP request driver'],
);
for my $stage (@production_stages) {
    my ($name, $label, $description) = @$stage;
    $case{$name} = {
        label => $label,
        description => $description,
        stage => $name,
        command => [$^X, '-Mblib', "$Bin/servers/linuxevent-production-stage.pl"],
    };
}

my $requests = 100_000;
my $warmup = 10_000;
my $connections = 100;
my $pipeline = 1;
my $response_bytes = 32;
my $repeats = 7;
my $timeout = 120;
my $read_budget_bytes = 0;
my $json_path;
my $case_list;
my $smoke = 0;
my $help = 0;

GetOptions(
    'requests=i'          => \$requests,
    'warmup=i'            => \$warmup,
    'connections=i'       => \$connections,
    'pipeline=i'          => \$pipeline,
    'response-bytes=i'    => \$response_bytes,
    'repeats=i'           => \$repeats,
    'timeout=f'           => \$timeout,
    'read-budget-bytes=i' => \$read_budget_bytes,
    'json=s'              => \$json_path,
    'cases=s'             => \$case_list,
    'smoke'               => \$smoke,
    'help'                => \$help,
) or usage(2);

usage(0) if $help;
if ($smoke) {
    $requests = 600;
    $warmup = 120;
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
die "response-bytes must be >= 0\n" if $response_bytes < 0;
die "repeats must be > 0\n" if $repeats <= 0;
die "timeout must be > 0\n" if $timeout <= 0;
die "read-budget-bytes must be >= 0\n" if $read_budget_bytes < 0;

my $request_wire = "GET /bench HTTP/1.1\r\nHost: benchmark.test\r\n\r\n";
my @names = ((map { $_->[0] } @production_stages), 'current_http');
if (defined $case_list) {
    my %known = map { $_ => 1 } keys %case;
    my @selected = grep { length } split /,/, $case_list;
    die "cases must name at least one benchmark case\n" if !@selected;
    for my $name (@selected) {
        die "unknown benchmark case '$name'\n" if !$known{$name};
    }
    @names = @selected;
}
my @records;

say 'Linux::Event::HTTP transaction lifecycle ladder';
say "requests=$requests warmup=$warmup connections=$connections pipeline=$pipeline response_bytes=$response_bytes repeats=$repeats read_budget_bytes=$read_budget_bytes";
say 'mode=single-process loopback-tcp shared-client cumulative-stages';

for my $repeat (1 .. $repeats) {
    for my $name (rotated_cases($repeat, @names)) {
        my $row = run_case($name, $request_wire);
        $row->{repeat} = $repeat;
        push @records, $row;
        printf "%-34s repeat=%d %10.1f req/s p50=%8.1f us p95=%8.1f us p99=%8.1f us max=%8.1f us\n",
            $case{$name}{label}, $repeat,
            @{$row}{qw(requests_per_second latency_us_p50 latency_us_p95 latency_us_p99 latency_us_max)};
    }
}

my @summary;
say '';
say 'Median comparison';
printf "%-34s %12s %12s %12s %12s %12s\n",
    'case', 'req/s', 'p50 us', 'p95 us', 'p99 us', 'max us';
for my $name (@names) {
    my @set = grep { $_->{case} eq $name } @records;
    my $row = {
        case => $name,
        label => $case{$name}{label},
        requests_per_second => median(map { $_->{requests_per_second} } @set),
        latency_us_p50 => median(map { $_->{latency_us_p50} } @set),
        latency_us_p95 => median(map { $_->{latency_us_p95} } @set),
        latency_us_p99 => median(map { $_->{latency_us_p99} } @set),
        latency_us_max => median(map { $_->{latency_us_max} } @set),
    };
    push @summary, $row;
    printf "%-34s %12.1f %12.1f %12.1f %12.1f %12.1f\n",
        $row->{label},
        @{$row}{qw(requests_per_second latency_us_p50 latency_us_p95 latency_us_p99 latency_us_max)};
}

say '';
say 'Step throughput changes';
for my $i (1 .. $#summary) {
    my ($before, $after) = @summary[$i - 1, $i];
    my $change = 100 * ($after->{requests_per_second} / $before->{requests_per_second} - 1);
    printf "%-10s -> %-10s %+.2f%%\n", $before->{case}, $after->{case}, $change;
}

if (defined $json_path) {
    my ($sysname, $nodename, $release, $version, $machine) = uname();
    my %contract = map { $_ => $case{$_}{description} } @names;
    $contract{common} = 'same raw client, 45-byte GET request wire, persistent loopback TCP sockets, unframed Linux::Event Stream transport, read budget, response payload size, and write transport; prod stages isolate the actual fused scalar-final builder and current minimal exchange state; prod_dispatch calls production callback/readiness/send; prod_connection uses the unmodified production Connection; current_http adds the Server wrapper; prebuilt wire is a diagnostic only, not an optimization';

    my $report = {
        benchmark => 'linux-event-http-transaction-ladder',
        benchmark_contract_version => 10,
        generated_at => strftime('%Y-%m-%dT%H:%M:%SZ', gmtime),
        environment => {
            perl => "$^V",
            linux_event => capture($^X, '-MLinux::Event', '-e', 'print $Linux::Event::VERSION'),
            picohttpparser => capture($^X, '-Mblib', '-MLinux::Event::HTTP::_HTTP1', '-e', 'print Linux::Event::HTTP::_HTTP1->pico_version'),
            os => $sysname,
            kernel => $release,
            machine => $machine,
        },
        configuration => {
            requests => $requests,
            warmup => $warmup,
            connections => $connections,
            pipeline => $pipeline,
            response_bytes => $response_bytes,
            repeats => $repeats,
            timeout => $timeout,
            read_budget_bytes => $read_budget_bytes,
            request_bytes => length($request_wire),
        },
        contract => \%contract,
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
        drive_phase(\@socket, $wire, $warmup, $pipeline, 0, $timeout) if $warmup;
        my $start = time;
        $latency = drive_phase(\@socket, $wire, $requests, $pipeline, 1, $timeout);
        $wall = time - $start;
        1;
    };
    my $error = $@;

    close $_ for @socket;
    stop_server($pid);

    if (!$ok) {
        my $detail = slurp_log('stdout', $stdout_path) . slurp_log('stderr', $stderr_path);
        unlink $stdout_path;
        unlink $stderr_path;
        die "$case{$name}{label} failed: $error$detail";
    }
    unlink $stdout_path;
    unlink $stderr_path;
    return {
        case => $name,
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
    my $stdout_path = "/tmp/le-http-transaction-$name-$$-out.log";
    my $stderr_path = "/tmp/le-http-transaction-$name-$$-err.log";
    my $pid = fork();
    die "fork $name: $!\n" if !defined $pid;

    if ($pid == 0) {
        $ENV{BENCH_PORT} = $port;
        $ENV{BENCH_RESPONSE_BYTES} = $response_bytes;
        $ENV{BENCH_READ_BUDGET_BYTES} = $read_budget_bytes;
        if (defined $case{$name}{stage}) {
            $ENV{BENCH_TRANSACTION_STAGE} = $case{$name}{stage};
        } else {
            delete $ENV{BENCH_TRANSACTION_STAGE};
        }
        if (defined $case{$name}{linuxevent_mode}) {
            $ENV{BENCH_LINUXEVENT_MODE} = $case{$name}{linuxevent_mode};
        } else {
            delete $ENV{BENCH_LINUXEVENT_MODE};
        }
        open STDOUT, '>', $stdout_path or POSIX::_exit(126);
        open STDERR, '>', $stderr_path or POSIX::_exit(126);
        child_exec(@{$case{$name}{command}});
        POSIX::_exit(127);
    }
    return ($pid, $stdout_path, $stderr_path);
}

sub wait_ready ($name, $pid, $port, $stdout_path, $stderr_path) {
    my $deadline = time + $timeout;
    while (time < $deadline) {
        my $fh = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp', Timeout => 0.1,
        );
        if ($fh) {
            close $fh;
            return;
        }
        my $done = waitpid($pid, POSIX::WNOHANG());
        die server_failure($name, $stdout_path, $stderr_path) if $done == $pid;
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
        my $done = waitpid($pid, POSIX::WNOHANG());
        return if $done == $pid || $done == -1;
        sleep 0.01;
    }
    kill 'KILL', $pid;
    waitpid($pid, 0);
}

sub free_port () {
    my $fh = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp', Listen => 1, ReuseAddr => 1,
    ) or die "allocate benchmark port: $!\n";
    my $port = $fh->sockport;
    close $fh;
    return $port;
}

sub open_clients ($port, $count) {
    my @socket;
    for (1 .. $count) {
        my $fh = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp',
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
            fh => $fh, quota => $quota, sent => 0, received => 0,
            buffer => '', sent_at => [],
        };
        $select->add($fh);
    }

    my @latency;
    my $received = 0;
    my $deadline = time + $phase_timeout;
    fill_pipeline($_, $wire, $depth, $measure) for values %state;

    while ($received < $count) {
        my $remaining = $deadline - time;
        die "benchmark client timed out after $phase_timeout seconds\n" if $remaining <= 0;
        my @ready = $select->can_read($remaining);
        die "benchmark client timed out after $phase_timeout seconds\n" if !@ready;

        for my $fh (@ready) {
            my $s = $state{fileno($fh)} or next;
            my $chunk = '';
            my $n = sysread($fh, $chunk, 65_536);
            if (!defined $n) {
                next if $! == EINTR;
                die "client read failed: $!\n";
            }
            die "server closed connection before benchmark phase completed\n" if $n == 0;
            $s->{buffer} .= $chunk;

            while (1) {
                my $head_end = index($s->{buffer}, "\r\n\r\n");
                last if $head_end < 0;
                my $head_len = $head_end + 4;
                my $head = substr($s->{buffer}, 0, $head_len);
                die "benchmark response was not HTTP 200\n" if $head !~ /\AHTTP\/1\.[01] 200\b/;
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
    return @values % 2 ? $values[$mid] : ($values[$mid - 1] + $values[$mid]) / 2;
}

sub rotated_cases ($repeat, @list) {
    return @list if @list < 2;
    my $offset = ($repeat - 1) % @list;
    return (@list[$offset .. $#list], @list[0 .. $offset - 1]);
}

sub child_exec (@command) {
    exec @command;
}

sub capture (@command) {
    pipe(my $reader, my $writer) or return undef;
    my $pid = fork();
    return undef if !defined $pid;
    if ($pid == 0) {
        close $reader;
        open STDOUT, '>&', $writer or POSIX::_exit(126);
        open STDERR, '>', '/dev/null' or POSIX::_exit(126);
        child_exec(@command);
        POSIX::_exit(127);
    }
    close $writer;
    local $/;
    my $output = <$reader>;
    close $reader;
    waitpid($pid, 0);
    return undef if $? != 0 || !defined $output;
    $output =~ s/\s+\z//;
    return length($output) ? $output : undef;
}

sub usage ($exit) {
    print <<'USAGE';
Usage: perl -Mblib bench/run-http-transaction-ladder.pl [options]

Options:
  --requests=N            measured responses per repeat (default 100000)
  --warmup=N              warmup responses per repeat (default 10000)
  --connections=N         persistent TCP connections (default 100)
  --pipeline=N            outstanding requests per connection (default 1)
  --response-bytes=N      response body bytes (default 32)
  --repeats=N             repeats (default 7)
  --read-budget-bytes=N   Linux::Event Stream read budget (default 0)
  --timeout=N             per-phase timeout seconds (default 120)
  --json=PATH             write machine-readable report
  --cases=LIST            comma-separated benchmark cases to run
  --smoke                 tiny one-repeat validation run
  --help                  show this help

The current ladder keeps manual construction diagnostics separate from the
production HTTP input path. prod_api, prod_wire, and prod_active use a plain
IO::Sock::Stream byte driver so they can isolate Response construction and wire
building without pretending to be HTTP Connection subclasses. prod_connection
uses the actual production Server::Connection with inherited native HTTP input,
and current_http adds the Server convenience wrapper.
USAGE
    exit $exit;
}
