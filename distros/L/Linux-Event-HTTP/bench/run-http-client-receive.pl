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
use POSIX qw(WNOHANG strftime uname);
use Scalar::Util qw(weaken);
use Time::HiRes qw(time sleep clock_gettime CLOCK_PROCESS_CPUTIME_ID);

use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP;
use Linux::Event::HTTP::Client::Connection;
use Linux::Event::HTTP::Request;

$SIG{PIPE} = 'IGNORE';

{
    package Linux::Event::HTTP::Bench::InstrumentedClientConnection;
    use parent 'Linux::Event::HTTP::Client::Connection';

    sub _http_client_native_fallback_input ($self, $bytes) {
        my $state = $self->data;
        my $bench = $state->{bench};
        if ($bench->{measuring}) {
            ++$bench->{input_calls};
            $bench->{input_bytes} += length($bytes);
            my $length = length($bytes);
            $bench->{input_max_bytes} = $length
                if $length > $bench->{input_max_bytes};
        }
        return $self->SUPER::_http_client_native_fallback_input($bytes);
    }
}

my %case = (
    cl32_drain => {
        label          => 'Content-Length 32 B, drain',
        framing        => 'content-length',
        response_bytes => 32,
        handling       => 'drain',
    },
    cl16k_drain => {
        label          => 'Content-Length 16 KiB, drain',
        framing        => 'content-length',
        response_bytes => 16_384,
        handling       => 'drain',
    },
    chunked16k_drain => {
        label          => 'chunked 16 KiB, drain',
        framing        => 'chunked',
        response_bytes => 16_384,
        handling       => 'drain',
    },
    cl16k_buffer => {
        label          => 'Content-Length 16 KiB, buffer_body',
        framing        => 'content-length',
        response_bytes => 16_384,
        handling       => 'buffer',
    },
    cl16k_on_body => {
        label          => 'Content-Length 16 KiB, on_body',
        framing        => 'content-length',
        response_bytes => 16_384,
        handling       => 'on_body',
    },
);

my $requests = 20_000;
my $warmup = 2_000;
my $connections = 100;
my $repeats = 5;
my $timeout = 30;
my $chunk_bytes = 4_096;
my $head_iterations = 100_000;
my $case_list = join(',', keys %case);
my $instrument_requests = 2_000;
my $json_path;
my $smoke = 0;
my $help = 0;

GetOptions(
    'requests=i'            => \$requests,
    'warmup=i'              => \$warmup,
    'connections=i'         => \$connections,
    'repeats=i'             => \$repeats,
    'timeout=f'             => \$timeout,
    'chunk-bytes=i'         => \$chunk_bytes,
    'head-iterations=i'     => \$head_iterations,
    'cases=s'               => \$case_list,
    'instrument-requests=i' => \$instrument_requests,
    'json=s'                => \$json_path,
    'smoke'                 => \$smoke,
    'help'                  => \$help,
) or usage(2);

usage(0) if $help;

if ($smoke) {
    $requests = 200;
    $warmup = 20;
    $connections = 4;
    $repeats = 1;
    $timeout = 10;
    $head_iterations = 1_000;
    $instrument_requests = 100;
}

die "requests must be > 0\n" if $requests <= 0;
die "warmup must be >= 0\n" if $warmup < 0;
die "connections must be > 0\n" if $connections <= 0;
die "repeats must be > 0\n" if $repeats <= 0;
die "timeout must be > 0\n" if $timeout <= 0;
die "chunk-bytes must be > 0\n" if $chunk_bytes <= 0;
die "head-iterations must be > 0\n" if $head_iterations <= 0;
die "instrument-requests must be > 0\n" if $instrument_requests <= 0;

my @selected = split /,/, $case_list;
for my $name (@selected) {
    die "unknown case '$name'\n" if !exists $case{$name};
}

say 'Linux::Event::HTTP client receive-path benchmark';
say "http_version=$Linux::Event::HTTP::VERSION linux_event=$Linux::Event::Loop::VERSION perl=$^V";
say "requests=$requests warmup=$warmup connections=$connections repeats=$repeats";
say "cases=" . join(',', @selected);

my @case_report;
for my $name (@selected) {
    my $spec = $case{$name};
    say '';
    say "$name: $spec->{label}";

    my @record;
    for my $repeat (1 .. $repeats) {
        my $row = run_client_case(
            spec          => $spec,
            requests      => $requests,
            warmup        => $warmup,
            connections   => $connections,
            timeout       => $timeout,
            chunk_bytes   => $chunk_bytes,
            instrumented  => 0,
        );
        $row->{repeat} = $repeat;
        push @record, $row;

        printf "repeat=%d %.1f responses/s client_cpu=%.3f us/response wall=%.6f s\n",
            $repeat,
            $row->{responses_per_second},
            $row->{client_cpu_us_per_response},
            $row->{wall_seconds};
    }

    my $instrument_count = $instrument_requests < $requests
        ? $instrument_requests : $requests;
    my $instrument_warmup = $warmup < 200 ? $warmup : 200;
    my $instrument = run_client_case(
        spec          => $spec,
        requests      => $instrument_count,
        warmup        => $instrument_warmup,
        connections   => $connections < $instrument_count
            ? $connections : $instrument_count,
        timeout       => $timeout,
        chunk_bytes   => $chunk_bytes,
        instrumented  => 1,
    );

    my $summary = {
        responses_per_second => median(
            map { $_->{responses_per_second} } @record,
        ),
        client_cpu_us_per_response => median(
            map { $_->{client_cpu_us_per_response} } @record,
        ),
        wall_seconds => median(map { $_->{wall_seconds} } @record),
        input_calls_per_response => $instrument->{input_calls_per_response},
        input_bytes_per_call => $instrument->{input_bytes_per_call},
        input_max_bytes => $instrument->{input_max_bytes},
    };

    printf "median %.1f responses/s client_cpu=%.3f us/response native_fallback=%.3f calls/response %.1f bytes/call max=%d\n",
        $summary->{responses_per_second},
        $summary->{client_cpu_us_per_response},
        $summary->{input_calls_per_response},
        $summary->{input_bytes_per_call},
        $summary->{input_max_bytes};

    push @case_report, {
        name    => $name,
        %$spec,
        summary => $summary,
        records => \@record,
        instrumentation => {
            requests => $instrument_count,
            warmup => $instrument_warmup,
            input_calls => $instrument->{input_calls},
            input_bytes => $instrument->{input_bytes},
            input_max_bytes => $instrument->{input_max_bytes},
            input_calls_per_response => $instrument->{input_calls_per_response},
            input_bytes_per_call => $instrument->{input_bytes_per_call},
        },
    };
}

say '';
my $head;
if (Linux::Event::HTTP::Client::Connection->can('_parse_response_head')) {
    $head = run_head_path_microbenchmark($head_iterations);
    printf "Perl response-head parse + framing: %.3f us/response (%d iterations)\n",
        $head->{cpu_us_per_response}, $head_iterations;
} else {
    say 'Perl response-head microbenchmark: not applicable to native client input';
}

if (defined $json_path) {
    my ($sysname, $nodename, $release, $version, $machine) = uname();
    my $report = {
        benchmark => 'linux-event-http-client-receive-path',
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
            repeats => $repeats,
            timeout => $timeout,
            chunk_bytes => $chunk_bytes,
            head_iterations => $head_iterations,
            instrument_requests => $instrument_requests,
            cases => \@selected,
        },
        head_path => $head,
        cases => \@case_report,
    };

    open my $fh, '>', $json_path or die "open $json_path: $!\n";
    print {$fh} JSON::PP->new->canonical->pretty->encode($report);
    close $fh or die "close $json_path: $!\n";
    say "json=$json_path";
}

sub run_client_case (%opt) {
    my $spec = $opt{spec};
    my $response = make_response(
        framing        => $spec->{framing},
        response_bytes => $spec->{response_bytes},
        chunk_bytes    => $opt{chunk_bytes},
    );

    my ($pid, $port) = spawn_raw_server(
        connections => $opt{connections},
        expected    => $opt{warmup} + $opt{requests},
        response    => $response,
    );

    my $loop = Linux::Event::Loop->new;
    my $bench = {
        loop              => $loop,
        phase             => undef,
        phase_expected    => 0,
        phase_completed   => 0,
        measuring         => 0,
        measured_requests => $opt{requests},
        warmup_requests   => $opt{warmup},
        response_bytes    => $spec->{response_bytes},
        handling          => $spec->{handling},
        connections       => [],
        error             => undef,
        on_body_calls     => 0,
        on_body_bytes     => 0,
        input_calls     => 0,
        input_bytes     => 0,
        input_max_bytes => 0,
        cpu_start         => undef,
        wall_start        => undef,
        cpu_seconds       => undef,
        wall_seconds      => undef,
    };

    my $class = $opt{instrumented}
        ? 'Linux::Event::HTTP::Bench::InstrumentedClientConnection'
        : 'Linux::Event::HTTP::Client::Connection';

    for my $index (0 .. $opt{connections} - 1) {
        my $state = {
            bench     => $bench,
            index     => $index,
            remaining => 0,
        };
        my $conn = $class->connect(
            loop => $loop,
            host => '127.0.0.1',
            port => $port,
            data => $state,
        );
        $state->{on_complete} = sub ($transaction) {
            _bench_complete($conn, $transaction);
        };
        $state->{on_error} = sub ($transaction, $error) {
            _bench_error($conn, $transaction, $error);
        };
        $state->{on_body} = sub ($transaction, $response, $bytes) {
            _bench_body($conn, $transaction, $response, $bytes);
        };
        push @{$bench->{connections}}, $conn;
    }

    Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => $opt{timeout},
        data => $bench,
        on_timer => sub ($timer) {
            my $state = $timer->data;
            return if defined $state->{wall_seconds};
            my @conn = map {
                my $d = $_->data;
                join(':',
                    $d->{index},
                    $d->{remaining},
                    defined($_->transaction) ? 'active' : 'idle',
                    $_->is_closed ? 'closed' : 'open',
                )
            } @{$state->{connections}};
            $state->{error} = "client benchmark timed out after $opt{timeout} seconds"
                . " phase=$state->{phase}"
                . " completed=$state->{phase_completed}/$state->{phase_expected}"
                . " connections=" . join(',', @conn);
            $state->{loop}->stop;
        },
    );

    if ($opt{warmup}) {
        begin_phase($bench, 'warmup', $opt{warmup});
    } else {
        begin_phase($bench, 'measure', $opt{requests});
    }

    $loop->run;

    my $error = $bench->{error};
    for my $conn (@{$bench->{connections}}) {
        $conn->close if !$conn->is_closed;
    }

    my $child_ok = wait_child($pid, $opt{timeout});
    die "$error\n" if defined $error;
    die "raw benchmark server failed\n" if !$child_ok;
    die "client benchmark ended without a measured result\n"
        if !defined $bench->{wall_seconds};

    my $row = {
        responses_per_second => $opt{requests} / $bench->{wall_seconds},
        client_cpu_us_per_response => $bench->{cpu_seconds} * 1_000_000
            / $opt{requests},
        wall_seconds => $bench->{wall_seconds},
        cpu_seconds => $bench->{cpu_seconds},
        on_body_calls => $bench->{on_body_calls},
        on_body_bytes => $bench->{on_body_bytes},
        input_calls => $bench->{input_calls},
        input_bytes => $bench->{input_bytes},
        input_max_bytes => $bench->{input_max_bytes},
    };

    $row->{input_calls_per_response} = $bench->{input_calls}
        / $opt{requests};
    $row->{input_bytes_per_call} = $bench->{input_calls}
        ? $bench->{input_bytes} / $bench->{input_calls}
        : 0;

    if ($spec->{handling} eq 'on_body') {
        my $expected = $opt{requests} * $spec->{response_bytes};
        die "on_body delivered $bench->{on_body_bytes} bytes, expected $expected\n"
            if $bench->{on_body_bytes} != $expected;
    }

    return $row;
}

sub begin_phase ($bench, $phase, $count) {
    $bench->{phase} = $phase;
    $bench->{phase_expected} = $count;
    $bench->{phase_completed} = 0;

    if ($phase eq 'measure') {
        $bench->{measuring} = 1;
        $bench->{on_body_calls} = 0;
        $bench->{on_body_bytes} = 0;
        $bench->{input_calls} = 0;
        $bench->{input_bytes} = 0;
        $bench->{input_max_bytes} = 0;
        $bench->{wall_start} = time;
        $bench->{cpu_start} = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
    } else {
        $bench->{measuring} = 0;
    }

    my $connection = $bench->{connections};
    my $base = int($count / @$connection);
    my $extra = $count % @$connection;

    for my $index (0 .. $#$connection) {
        my $quota = $base + ($index < $extra ? 1 : 0);
        my $state = $connection->[$index]->data;
        $state->{remaining} = $quota;
        issue_next($connection->[$index]) if $quota;
    }

    return;
}

sub issue_next ($conn) {
    my $state = $conn->data;
    my $bench = $state->{bench};
    return if $state->{remaining} <= 0;
    --$state->{remaining};

    my $request = Linux::Event::HTTP::Request->new(
        method  => 'GET',
        target  => '/bench',
        headers => [ [ Host => 'benchmark.test' ] ],
    );

    my %option = (
        on_complete => $state->{on_complete},
        on_error    => $state->{on_error},
    );

    if ($bench->{handling} eq 'on_body') {
        $option{on_body} = $state->{on_body};
    } elsif ($bench->{handling} eq 'buffer') {
        $option{buffer_body} = $bench->{response_bytes};
    }

    $conn->request($request, %option);
    return;
}

sub _bench_complete ($conn, $transaction) {
    my $state = $conn->data;
    my $bench = $state->{bench};

    ++$bench->{phase_completed};

    if ($bench->{phase_completed} == $bench->{phase_expected}) {
        if ($bench->{phase} eq 'warmup') {
            begin_phase($bench, 'measure', $bench->{measured_requests});
            return;
        }

        my $cpu_end = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
        my $wall_end = time;
        $bench->{cpu_seconds} = $cpu_end - $bench->{cpu_start};
        $bench->{wall_seconds} = $wall_end - $bench->{wall_start};
        $bench->{measuring} = 0;
        $bench->{loop}->stop;
        return;
    }

    issue_next($conn) if $state->{remaining} > 0;
    return;
}

sub _bench_body ($conn, $transaction, $response, $bytes) {
    my $bench = $conn->data->{bench};
    if ($bench->{measuring}) {
        ++$bench->{on_body_calls};
        $bench->{on_body_bytes} += length($bytes);
    }
    return;
}

sub _bench_error ($conn, $transaction, $error) {
    my $bench = $conn->data->{bench};
    $bench->{error} //= $error;
    $bench->{loop}->stop;
    return;
}

sub spawn_raw_server (%opt) {
    pipe my $reader, my $writer or die "pipe: $!\n";
    $writer->autoflush(1);

    my $pid = fork();
    die "fork: $!\n" if !defined $pid;

    if ($pid == 0) {
        close $reader;
        my $ok = eval {
            raw_server(
                result_fh   => $writer,
                connections => $opt{connections},
                expected    => $opt{expected},
                response    => $opt{response},
            );
            1;
        };
        if (!$ok) {
            my $error = "$@";
            warn "raw benchmark server: $error";
            close $writer;
            POSIX::_exit(1);
        }
        close $writer;
        POSIX::_exit(0);
    }

    close $writer;
    my $line = <$reader>;
    die "raw benchmark server exited before reporting port\n"
        if !defined $line || $line !~ /\APORT (\d+)\s*\z/;
    close $reader;
    return ($pid, 0 + $1);
}

sub raw_server (%opt) {
    my $listen = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        Listen    => $opt{connections} + 16,
        ReuseAddr => 1,
    ) or die "listen: $!\n";

    print {$opt{result_fh}} 'PORT ', $listen->sockport, "\n";
    $opt{result_fh}->flush;

    my @socket;
    for (1 .. $opt{connections}) {
        my $fh = $listen->accept or die "accept: $!\n";
        $fh->autoflush(1);
        push @socket, $fh;
    }
    close $listen;

    my $select = IO::Select->new(@socket);
    my %buffer = map { fileno($_) => '' } @socket;
    my $seen = 0;

    while ($seen < $opt{expected}) {
        my @ready = $select->can_read(10);
        die "raw server timed out waiting for requests\n" if !@ready;

        for my $fh (@ready) {
            my $chunk = '';
            my $n = sysread($fh, $chunk, 65_536);
            if (!defined $n) {
                next if $! == EINTR;
                die "raw server read failed: $!\n";
            }
            die "client closed raw server connection early"
                . " after $seen/$opt{expected} requests\n" if $n == 0;

            my $fd = fileno($fh);
            $buffer{$fd} .= $chunk;

            while (1) {
                my $end = index($buffer{$fd}, "\r\n\r\n");
                last if $end < 0;
                substr($buffer{$fd}, 0, $end + 4, '');
                ++$seen;
                write_all($fh, $opt{response});
                last if $seen >= $opt{expected};
            }

            last if $seen >= $opt{expected};
        }
    }

    sleep 0.02;
    close $_ for @socket;
    return;
}

sub write_all ($fh, $bytes) {
    my $offset = 0;
    while ($offset < length($bytes)) {
        my $written = syswrite(
            $fh, $bytes, length($bytes) - $offset, $offset,
        );
        if (!defined $written) {
            next if $! == EINTR;
            die "raw server write failed: $!\n";
        }
        die "raw server write returned zero bytes\n" if $written == 0;
        $offset += $written;
    }
    return;
}

sub make_response (%opt) {
    my $body = 'x' x $opt{response_bytes};

    if ($opt{framing} eq 'content-length') {
        return "HTTP/1.1 200 OK\r\n"
            . "Content-Length: $opt{response_bytes}\r\n"
            . "Connection: keep-alive\r\n"
            . "\r\n"
            . $body;
    }

    die "unknown response framing '$opt{framing}'\n"
        if $opt{framing} ne 'chunked';

    my $wire = "HTTP/1.1 200 OK\r\n"
        . "Transfer-Encoding: chunked\r\n"
        . "Connection: keep-alive\r\n"
        . "\r\n";

    my $offset = 0;
    while ($offset < length($body)) {
        my $length = length($body) - $offset;
        $length = $opt{chunk_bytes} if $length > $opt{chunk_bytes};
        $wire .= sprintf("%x\r\n", $length);
        $wire .= substr($body, $offset, $length);
        $wire .= "\r\n";
        $offset += $length;
    }

    $wire .= "0\r\n\r\n";
    return $wire;
}

sub wait_child ($pid, $timeout) {
    my $deadline = time + $timeout;
    while (time < $deadline) {
        my $result = waitpid($pid, WNOHANG);
        return $? == 0 if $result == $pid;
        sleep 0.01;
    }

    kill 'TERM', $pid;
    waitpid($pid, 0);
    return 0;
}

sub run_head_path_microbenchmark ($iterations) {
    my $wire = "HTTP/1.1 200 OK\r\n"
        . "Content-Length: 32\r\n"
        . "Connection: keep-alive\r\n"
        . "\r\n";

    my $request = Linux::Event::HTTP::Request->new(
        method  => 'GET',
        target  => '/bench',
        headers => [ [ Host => 'benchmark.test' ] ],
    );

    my $checksum = 0;
    my $start = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);

    for (1 .. $iterations) {
        my ($response, $consumed)
            = Linux::Event::HTTP::Client::Connection::_parse_response_head($wire);
        my $state
            = Linux::Event::HTTP::Client::Connection::_response_transfer_mode(
                $request, $response,
            );
        $checksum += $consumed + $response->status + $state->{remaining};
    }

    my $seconds = clock_gettime(CLOCK_PROCESS_CPUTIME_ID) - $start;
    die "head-path benchmark checksum failed\n" if !$checksum;

    return {
        iterations => $iterations,
        cpu_seconds => $seconds,
        cpu_us_per_response => $seconds * 1_000_000 / $iterations,
    };
}

sub median (@value) {
    return 0 if !@value;
    @value = sort { $a <=> $b } @value;
    my $middle = int(@value / 2);
    return @value % 2
        ? $value[$middle]
        : ($value[$middle - 1] + $value[$middle]) / 2;
}

sub usage ($status) {
    print <<'USAGE';
usage: bench/run-http-client-receive.pl [options]

  --cases=LIST              comma-separated benchmark cases
                            cl32_drain,cl16k_drain,chunked16k_drain,
                            cl16k_buffer,cl16k_on_body
  --requests=N              measured responses per repeat (default 20000)
  --warmup=N                warmup responses per repeat (default 2000)
  --connections=N           concurrent persistent connections (default 100)
  --repeats=N               benchmark repeats (default 5)
  --timeout=SECONDS         timeout per run (default 30)
  --chunk-bytes=N           chunk payload bytes (default 4096)
  --head-iterations=N       response-head microbenchmark iterations (default 100000)
  --instrument-requests=N   short on_data instrumentation run size (default 2000)
  --json=PATH               write machine-readable report
  --smoke                   tiny correctness/sanity workload
  --help                    show this help
USAGE
    exit $status;
}
