#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Errno qw(EINTR);
use Getopt::Long qw(GetOptions);
use IO::Handle ();
use IO::Select;
use IO::Socket::INET;
use POSIX qw(WNOHANG);
use Time::HiRes qw(time sleep);

use Linux::Event::Loop;
use Linux::Event::HTTP::Server::Connection;
use Linux::Event::HTTP::Server;

$SIG{PIPE} = 'IGNORE';

{
    package Linux::Event::HTTP::Bench::OrdinaryRequestConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub on_request ($self, $request, $response) {
        $response->body($self->data->{payload});
        return;
    }
}

{
    package Linux::Event::HTTP::Bench::OrdinaryRequestEndConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub on_request ($self, $request, $response) {
        return;
    }

    sub on_request_end ($self, $request, $response) {
        $response->body($self->data->{payload});
        return;
    }
}

my $requests = 20_000;
my $warmup = 2_000;
my $connections = 100;
my $pipeline = 1;
my $response_bytes = 32;
my $repeats = 5;
my $timeout = 120;
my $smoke = 0;
my $help = 0;

GetOptions(
    'requests=i'       => \$requests,
    'warmup=i'         => \$warmup,
    'connections=i'    => \$connections,
    'pipeline=i'       => \$pipeline,
    'response-bytes=i' => \$response_bytes,
    'repeats=i'        => \$repeats,
    'timeout=f'        => \$timeout,
    'smoke'            => \$smoke,
    'help'             => \$help,
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
die "response-bytes must be >= 0\n" if $response_bytes < 0;
die "repeats must be > 0\n" if $repeats <= 0;
die "timeout must be > 0\n" if $timeout <= 0;

my $request_wire = "GET /bench HTTP/1.1\r\nHost: benchmark.test\r\n\r\n";
my @mode = qw(ordinary_request ordinary_request_end);
my %label = (
    ordinary_request     => 'on_request -> Response->body',
    ordinary_request_end => 'on_request_end -> Response->body',
);
my %class = (
    ordinary_request     => 'Linux::Event::HTTP::Bench::OrdinaryRequestConnection',
    ordinary_request_end => 'Linux::Event::HTTP::Bench::OrdinaryRequestEndConnection',
);
my %records;

say 'Linux::Event::HTTP response finalization benchmark';
say "requests=$requests warmup=$warmup connections=$connections pipeline=$pipeline response_bytes=$response_bytes repeats=$repeats";
say 'ordinary_request = real Connection on_request($conn,$req,$res) + Response->body';
say 'ordinary_request_end = real Connection no-op on_request + on_request_end($conn,$req,$res) + Response->body';

for my $repeat (1 .. $repeats) {
    my @order = $repeat % 2 ? @mode : reverse @mode;
    for my $mode (@order) {
        my $row = run_case($mode, $request_wire);
        push @{$records{$mode}}, $row;
        printf "%-31s repeat=%d %10.1f req/s p50=%8.1f us p95=%8.1f us p99=%8.1f us max=%8.1f us\n",
            $label{$mode}, $repeat,
            @{$row}{qw(requests_per_second latency_us_p50 latency_us_p95 latency_us_p99 latency_us_max)};
    }
}

say '';
say 'Median comparison';
printf "%-31s %12s %12s %12s %12s %12s\n",
    'mode', 'req/s', 'p50 us', 'p95 us', 'p99 us', 'max us';
my %median;
for my $mode (@mode) {
    my @set = @{$records{$mode}};
    $median{$mode} = {
        requests_per_second => median(map { $_->{requests_per_second} } @set),
        latency_us_p50 => median(map { $_->{latency_us_p50} } @set),
        latency_us_p95 => median(map { $_->{latency_us_p95} } @set),
        latency_us_p99 => median(map { $_->{latency_us_p99} } @set),
        latency_us_max => median(map { $_->{latency_us_max} } @set),
    };
    printf "%-31s %12.1f %12.1f %12.1f %12.1f %12.1f\n",
        $label{$mode},
        @{$median{$mode}}{qw(requests_per_second latency_us_p50 latency_us_p95 latency_us_p99 latency_us_max)};
}

my $ordinary_vs_end = 100 * (
    $median{ordinary_request}{requests_per_second}
        / $median{ordinary_request_end}{requests_per_second} - 1
);
printf "ordinary_request vs request_end    %+.2f%%\n", $ordinary_vs_end;

sub run_case ($mode, $wire) {
    my ($pid, $result_fh, $port) = start_server($mode);

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
    close $result_fh;

    die "$label{$mode} failed: $error" if !$ok;

    return {
        requests_per_second => $requests / $wall,
        latency_us_p50 => percentile_us($latency, 50),
        latency_us_p95 => percentile_us($latency, 95),
        latency_us_p99 => percentile_us($latency, 99),
        latency_us_max => max_us($latency),
    };
}

sub start_server ($mode) {
    pipe my $reader, my $writer or die "pipe: $!\n";
    $writer->autoflush(1);

    my $pid = fork();
    die "fork $mode: $!\n" if !defined $pid;

    if ($pid == 0) {
        close $reader;
        my $loop = Linux::Event::Loop->new;
        my $server = Linux::Event::HTTP::Server->new(
            loop => $loop,
            host => '127.0.0.1',
            port => 0,
            data => { payload => 'x' x $response_bytes },
            connection_class => $class{$mode},
        );
        print {$writer} "PORT ", $server->port, "\n";
        $writer->flush;
        $loop->run;
        POSIX::_exit(0);
    }

    close $writer;
    my $deadline = time + $timeout;
    my $select = IO::Select->new($reader);
    while (time < $deadline) {
        my @ready = $select->can_read($deadline - time);
        last if !@ready;
        my $line = <$reader>;
        if (defined($line) && $line =~ /\APORT (\d+)\s*\z/) {
            return ($pid, $reader, 0 + $1);
        }
        last if !defined $line;
    }

    stop_server($pid);
    close $reader;
    die "benchmark server $mode did not report a listening port\n";
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
    return;
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
    return;
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
    return;
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

sub usage ($status) {
    print <<'USAGE';
usage: bench/run-http-final-response.pl [options]

  --requests=N        measured requests per mode/repeat (default 20000)
  --warmup=N          warmup requests per mode/repeat (default 2000)
  --connections=N     concurrent TCP connections (default 100)
  --pipeline=N        max outstanding requests per connection (default 1)
  --response-bytes=N  fixed response body bytes (default 32)
  --repeats=N         rotated benchmark repeats (default 5)
  --timeout=SECONDS   server/client phase timeout (default 120)
  --smoke             tiny keep-alive correctness workload
  --help              show this help
USAGE
    exit $status;
}
