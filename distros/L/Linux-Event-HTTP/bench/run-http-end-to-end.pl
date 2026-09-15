#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Errno qw(EINTR);
use Getopt::Long qw(GetOptions);
use IO::Handle ();
use IO::Select;
use IO::Socket::INET;
use JSON::PP ();
use POSIX qw(strftime uname);
use Time::HiRes qw(time clock_gettime CLOCK_PROCESS_CPUTIME_ID);

use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP;
use Linux::Event::HTTP::Server::Connection;
use Linux::Event::HTTP::Server;

{
    package Linux::Event::HTTP::Bench::Connection;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub on_request ($self, $request, $response) {
        my $state = $self->data;
        if (!$state->{started}) {
            $state->{started} = 1;
            $state->{wall_start} = Time::HiRes::time();
            $state->{cpu_start} = Time::HiRes::clock_gettime(
                Time::HiRes::CLOCK_PROCESS_CPUTIME_ID(),
            );
        }
        return;
    }

    sub on_request_end ($self, $request, $response) {
        my $state = $self->data;
        ++$state->{seen};
        $response->body($state->{payload});

        if ($state->{seen} == $state->{expected}) {
            Linux::Event::Kernel::Timer->new(
                loop => $self->loop,
                after => 0.02,
                data => $state,
                on_timer => sub ($timer) {
                    my $s = $timer->data;
                    $s->{wall_seconds} = Time::HiRes::time() - $s->{wall_start};
                    $s->{cpu_seconds} = Time::HiRes::clock_gettime(
                        Time::HiRes::CLOCK_PROCESS_CPUTIME_ID(),
                    ) - $s->{cpu_start};
                    $s->{loop_stats} = $s->{loop}->stats;
                    my $out = {
                        seen => $s->{seen},
                        wall_seconds => $s->{wall_seconds},
                        cpu_seconds => $s->{cpu_seconds},
                        loop_stats => $s->{loop_stats},
                    };
                    print {$s->{result_fh}}
                        'RESULT ', JSON::PP->new->canonical->encode($out), "\n";
                    $s->{result_fh}->flush;
                    $s->{loop}->stop;
                },
            );
        }
        return;
    }
}

my $requests = 20_000;
my $warmup = 2_000;
my $connections = 100;
my $pipeline = 1;
my $request_body_bytes = 0;
my $response_bytes = 32;
my $repeats = 5;
my $timeout = 15;
my $profile = 0;
my $json_path;
my $smoke = 0;
my $help = 0;

GetOptions(
    'requests=i'           => \$requests,
    'warmup=i'             => \$warmup,
    'connections=i'        => \$connections,
    'pipeline=i'           => \$pipeline,
    'request-body-bytes=i' => \$request_body_bytes,
    'response-bytes=i'     => \$response_bytes,
    'repeats=i'            => \$repeats,
    'timeout=f'            => \$timeout,
    'profile!'             => \$profile,
    'json=s'               => \$json_path,
    'smoke'                => \$smoke,
    'help'                 => \$help,
) or usage(2);

usage(0) if $help;
if ($smoke) {
    $requests = 200;
    $warmup = 20;
    $connections = 4;
    $pipeline = 2;
    $request_body_bytes = 0;
    $response_bytes = 8;
    $repeats = 1;
    $timeout = 10;
}

die "requests must be > 0\n" if $requests <= 0;
die "warmup must be >= 0\n" if $warmup < 0;
die "connections must be > 0\n" if $connections <= 0;
die "pipeline must be > 0\n" if $pipeline <= 0;
die "request-body-bytes must be >= 0\n" if $request_body_bytes < 0;
die "response-bytes must be >= 0\n" if $response_bytes < 0;
die "repeats must be > 0\n" if $repeats <= 0;
die "timeout must be > 0\n" if $timeout <= 0;

my $request_wire = make_request($request_body_bytes);
my @records;

say 'Linux::Event::HTTP end-to-end benchmark';
say "http_version=$Linux::Event::HTTP::VERSION linux_event=$Linux::Event::Loop::VERSION perl=$^V";
say "requests=$requests warmup=$warmup connections=$connections pipeline=$pipeline request_body_bytes=$request_body_bytes response_bytes=$response_bytes repeats=$repeats profile=$profile";

for my $repeat (1 .. $repeats) {
    my ($pid, $result_fh, $port) = spawn_server(
        expected => $warmup + $requests,
        response_bytes => $response_bytes,
        profile => $profile,
    );

    my @socket = open_clients($port, $connections);
    drive_phase(\@socket, $request_wire, $warmup, $pipeline, 0, $timeout)
        if $warmup;

    my $start = time;
    my $latency = drive_phase(
        \@socket, $request_wire, $requests, $pipeline, 1, $timeout,
    );
    my $wall = time - $start;

    close $_ for @socket;

    my $server = read_server_result($result_fh, $pid, $timeout);
    my $row = {
        repeat => $repeat,
        requests => $requests,
        wall_seconds => $wall,
        requests_per_second => $requests / $wall,
        latency_us_p50 => percentile_us($latency, 50),
        latency_us_p95 => percentile_us($latency, 95),
        latency_us_p99 => percentile_us($latency, 99),
        latency_us_max => max_us($latency),
        server_cpu_us_per_request => $server->{cpu_seconds} * 1_000_000
            / ($warmup + $requests),
        server_wall_seconds => $server->{wall_seconds},
        loop_stats => $server->{loop_stats},
    };
    push @records, $row;

    printf "repeat=%d %.1f req/s p50=%.1f us p95=%.1f us p99=%.1f us max=%.1f us server_cpu=%.3f us/req\n",
        $repeat,
        $row->{requests_per_second},
        $row->{latency_us_p50},
        $row->{latency_us_p95},
        $row->{latency_us_p99},
        $row->{latency_us_max},
        $row->{server_cpu_us_per_request};
}

my $summary = {
    requests_per_second => median(map { $_->{requests_per_second} } @records),
    latency_us_p50 => median(map { $_->{latency_us_p50} } @records),
    latency_us_p95 => median(map { $_->{latency_us_p95} } @records),
    latency_us_p99 => median(map { $_->{latency_us_p99} } @records),
    latency_us_max => median(map { $_->{latency_us_max} } @records),
    server_cpu_us_per_request => median(
        map { $_->{server_cpu_us_per_request} } @records,
    ),
};

say '';
printf "median %.1f req/s p50=%.1f us p95=%.1f us p99=%.1f us max=%.1f us server_cpu=%.3f us/req\n",
    $summary->{requests_per_second},
    $summary->{latency_us_p50},
    $summary->{latency_us_p95},
    $summary->{latency_us_p99},
    $summary->{latency_us_max},
    $summary->{server_cpu_us_per_request};

if (defined $json_path) {
    my ($sysname, $nodename, $release, $version, $machine) = uname();
    my $report = {
        benchmark => 'linux-event-http-end-to-end',
        benchmark_contract_version => 1,
        generated_at => strftime('%Y-%m-%dT%H:%M:%SZ', gmtime),
        environment => {
            perl => "$^V",
            linux_event => "$Linux::Event::Loop::VERSION",
            linux_event_http => "$Linux::Event::HTTP::VERSION",
            os => $sysname,
            kernel => $release,
            machine => $machine,
        },
        configuration => {
            requests => $requests,
            warmup => $warmup,
            connections => $connections,
            pipeline => $pipeline,
            request_body_bytes => $request_body_bytes,
            response_bytes => $response_bytes,
            repeats => $repeats,
            timeout => $timeout,
            profile => $profile ? JSON::PP::true : JSON::PP::false,
        },
        summary => $summary,
        records => \@records,
    };
    open my $fh, '>', $json_path or die "open $json_path: $!\n";
    print {$fh} JSON::PP->new->canonical->pretty->encode($report);
    close $fh or die "close $json_path: $!\n";
    say "json=$json_path";
}

sub spawn_server (%opt) {
    pipe my $reader, my $writer or die "pipe: $!\n";
    $writer->autoflush(1);

    my $pid = fork();
    die "fork: $!\n" if !defined $pid;

    if ($pid == 0) {
        close $reader;

        my $loop = Linux::Event::Loop->new;
        $loop->profile($opt{profile} ? 1 : 0);
        $loop->reset_stats;

        my $state = {
            loop => $loop,
            result_fh => $writer,
            payload => 'x' x $opt{response_bytes},
            expected => $opt{expected},
            seen => 0,
            started => 0,
        };

        my $server = Linux::Event::HTTP::Server->new(
            loop => $loop,
            host => '127.0.0.1',
            port => 0,
            data => $state,
            connection_class => 'Linux::Event::HTTP::Bench::Connection',
        );

        print {$writer} "PORT ", $server->port, "\n";
        $writer->flush;
        $loop->run;
        $server->close;
        close $writer;
        POSIX::_exit(0);
    }

    close $writer;
    my $line = <$reader>;
    die "benchmark server exited before reporting port\n"
        if !defined $line || $line !~ /\APORT (\d+)\s*\z/;
    return ($pid, $reader, 0 + $1);
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
        my $fd = fileno($fh);
        $state{$fd} = {
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

    for my $s (values %state) {
        fill_pipeline($s, $wire, $depth, $measure);
    }

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

sub make_request ($body_bytes) {
    my $body = 'b' x $body_bytes;
    return $body_bytes
        ? "POST /bench HTTP/1.1\r\nHost: benchmark.test\r\nContent-Length: $body_bytes\r\n\r\n$body"
        : "GET /bench HTTP/1.1\r\nHost: benchmark.test\r\n\r\n";
}

sub read_server_result ($fh, $pid, $wait_timeout) {
    my $select = IO::Select->new($fh);
    my $deadline = time + $wait_timeout;
    my $result;

    while (time < $deadline) {
        my @ready = $select->can_read($deadline - time);
        last if !@ready;
        my $line = <$fh>;
        last if !defined $line;
        if ($line =~ /\ARESULT (.+)\s*\z/) {
            $result = JSON::PP->new->decode($1);
            last;
        }
    }

    if (!$result) {
        kill 'TERM', $pid;
        waitpid($pid, 0);
        die "benchmark server did not report final statistics\n";
    }

    waitpid($pid, 0);
    close $fh;
    die "benchmark server exited unsuccessfully\n" if $? != 0;
    return $result;
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
usage: bench/run-http-end-to-end.pl [options]

  --requests=N             measured requests per repeat (default 20000)
  --warmup=N               warmup requests per repeat (default 2000)
  --connections=N          concurrent TCP connections (default 100)
  --pipeline=N             max outstanding requests per connection (default 1)
  --request-body-bytes=N   fixed request body bytes (default 0)
  --response-bytes=N       fixed response body bytes (default 32)
  --repeats=N              benchmark repeats (default 5)
  --timeout=SECONDS        timeout for each phase/result (default 15)
  --profile                 enable Linux::Event native timing collection
  --json=PATH               write machine-readable report
  --smoke                   tiny CI/sanity workload
  --help                    show this help
USAGE
    exit $status;
}
