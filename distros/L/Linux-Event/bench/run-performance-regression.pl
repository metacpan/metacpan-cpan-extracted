#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use FindBin qw($Bin);
use Getopt::Long qw(GetOptions);
use JSON::PP qw();
use POSIX qw(strftime uname);
use Socket qw(
    AF_INET AF_UNIX INADDR_LOOPBACK PF_UNSPEC
    SOCK_STREAM SOCK_NONBLOCK SOCK_CLOEXEC
    SOL_SOCKET SO_LINGER
);
use Time::HiRes qw(
    clock_gettime CLOCK_MONOTONIC CLOCK_PROCESS_CPUTIME_ID
);

use lib "$Bin/../blib/lib", "$Bin/../blib/arch", "$Bin/../lib";

my @all_workloads = qw(
    registration-lifecycle
    timer-lifecycle
    timer-expiration
    raw-stream-lifecycle
    framed-stream-lifecycle
    raw-stream-throughput
    deadline-stream-throughput
    framed-stream-throughput
    connect-listener-lifecycle
);
my %known_workload = map { $_ => 1 } @all_workloads;

my $contract_version = 3;
my $quick = 0;
my $repeats;
my $iterations;
my $pool;
my $clients;
my $messages;
my $connections;
my $warmup_iterations;
my $warmup_messages;
my $warmup_connections;
my @workloads = @all_workloads;
my $json_path = 'bench/results/performance-regression.json';
my $baseline_path;
my $threshold_percent = 10;
my $fail_on_regression = 0;
my $help = 0;

GetOptions(
    'quick!'              => \$quick,
    'repeats=i'           => \$repeats,
    'iterations=i'        => \$iterations,
    'pool=i'              => \$pool,
    'clients=i'           => \$clients,
    'messages=i'          => \$messages,
    'connections=i'       => \$connections,
    'warmup-iterations=i' => \$warmup_iterations,
    'warmup-messages=i'   => \$warmup_messages,
    'warmup-connections=i' => \$warmup_connections,
    'workloads=s'         => sub { @workloads = split /,/, $_[1] },
    'json=s'              => \$json_path,
    'baseline=s'          => \$baseline_path,
    'threshold-percent=f' => \$threshold_percent,
    'fail-on-regression!' => \$fail_on_regression,
    'help'                => \$help,
) or usage(2);
usage(0) if $help;

my %preset = $quick
    ? (
        repeats => 3,
        iterations => 10_000,
        pool => 64,
        clients => 16,
        messages => 100,
        connections => 500,
        warmup_iterations => 500,
        warmup_messages => 10,
        warmup_connections => 50,
    )
    : (
        repeats => 7,
        iterations => 100_000,
        pool => 256,
        clients => 100,
        messages => 1_000,
        connections => 10_000,
        warmup_iterations => 5_000,
        warmup_messages => 100,
        warmup_connections => 1_000,
    );

$repeats           //= $preset{repeats};
$iterations        //= $preset{iterations};
$pool              //= $preset{pool};
$clients           //= $preset{clients};
$messages          //= $preset{messages};
$connections       //= $preset{connections};
$warmup_iterations //= $preset{warmup_iterations};
$warmup_messages   //= $preset{warmup_messages};
$warmup_connections //= $preset{warmup_connections};

die "at least one workload is required\n" if !@workloads;
die "unknown workload: $_\n"
    for grep { !$known_workload{$_} } @workloads;
my %seen;
die "workloads must not contain duplicates\n"
    if grep { $seen{$_}++ } @workloads;
die "repeats must be positive\n" if $repeats < 1;
die "iterations must be positive\n" if $iterations < 1;
die "pool must be positive\n" if $pool < 1;
die "clients must be positive\n" if $clients < 1;
die "messages must be positive\n" if $messages < 1;
die "connections must be positive\n" if $connections < 1;
die "warmup values must be non-negative\n"
    if grep { $_ < 0 }
        ($warmup_iterations, $warmup_messages, $warmup_connections);
die "threshold-percent must be non-negative\n" if $threshold_percent < 0;

require Linux::Event;
require Linux::Event::IO::Sock::Listener;
require Linux::Event::Loop;
require Linux::Event::IO::Sock::Stream;
require Linux::Event::IO::Sock::Stream;
require Linux::Event::Kernel::Timer;
define_benchmark_classes();

my %configuration = (
    repeats => $repeats,
    iterations => $iterations,
    pool => $pool,
    clients => $clients,
    messages => $messages,
    connections => $connections,
    warmup_iterations => $warmup_iterations,
    warmup_messages => $warmup_messages,
    warmup_connections => $warmup_connections,
    workloads => \@workloads,
);

say 'Linux::Event performance-regression benchmark';
say "version=$Linux::Event::VERSION perl=$^V contract=$contract_version";
say 'workloads=' . join(',', @workloads);
say "repeats=$repeats threshold=$threshold_percent%";

my @records;
for my $repeat (1 .. $repeats) {
    my @order = rotated_workloads($repeat);
    for my $position (0 .. $#order) {
        my $workload = $order[$position];
        my $row = run_workload($workload);
        $row->{workload} = $workload;
        $row->{repeat} = $repeat;
        $row->{order_position} = $position + 1;
        push @records, $row;
        printf "%-30s repeat=%d %12.1f %-13s cpu=%9.3f us/%s\n",
            $workload,
            $repeat,
            $row->{operations_per_second},
            "$row->{unit}/s",
            $row->{cpu_us_per_operation},
            $row->{unit};
    }
}

my @summary = summarize(\@records);
say "\nMedian summary";
printf "%-30s %14s %16s\n", 'workload', 'rate', 'cpu us/op';
for my $row (@summary) {
    printf "%-30s %14.1f %16.3f\n",
        $row->{workload},
        $row->{operations_per_second},
        $row->{cpu_us_per_operation};
}

my $report = {
    benchmark => 'linux-event-performance-regression',
    benchmark_contract_version => $contract_version,
    generated_at => strftime('%Y-%m-%dT%H:%M:%SZ', gmtime),
    linux_event_version => "$Linux::Event::VERSION",
    environment => environment_info(),
    configuration => \%configuration,
    records => \@records,
    summary => \@summary,
    notes => [
        'Each summary value is the median of rotated-order repeats.',
        'Lifecycle socketpairs are allocated outside timed regions.',
        'Timer lifecycle measures attach plus cancellation on one shared timerfd.',
        'Timer expiration measures zero-delay delivery through the native heap.',
        'Throughput workloads use one outstanding message per client.',
        'Deadline throughput enables idle tracking without allowing expiration.',
        'The connection workload measures the complete public connect/listen handoff.',
        'Compare only reports with the same contract and configuration.',
    ],
};

my $regression_count = 0;
if (defined $baseline_path) {
    my $baseline = read_json($baseline_path);
    my $comparison = compare_reports($baseline, $report);
    $report->{comparison} = $comparison;
    $regression_count = scalar grep { $_->{regression} }
        @{ $comparison->{workloads} };
    print_comparison($comparison);
}

write_json($json_path, $report);
say "\nWrote $json_path";

exit 2 if $fail_on_regression && $regression_count;
exit 0;

sub usage ($status) {
    print <<'USAGE';
Usage:
  perl -Mblib bench/run-performance-regression.pl [options]

Capture a stable full baseline:
  perl -Mblib bench/run-performance-regression.pl \
    --json bench/results/performance-baseline.json

Compare a later build with the same configuration:
  perl -Mblib bench/run-performance-regression.pl \
    --baseline bench/results/performance-baseline.json \
    --threshold-percent 10 --fail-on-regression \
    --json bench/results/performance-candidate.json

Useful options:
  --quick                    shorter development preset
  --repeats N                median sample count
  --iterations N             lifecycle operations per repeat
  --pool N                   reusable socketpairs for lifecycle workloads
  --clients N                concurrent throughput/connection clients
  --messages N               measured messages per throughput client
  --connections N            measured connect/listen lifecycles
  --warmup-iterations N      lifecycle warmup operations
  --warmup-messages N        throughput warmup messages per client
  --warmup-connections N     connect/listen warmup operations
  --workloads LIST           comma-separated workload subset
  --json PATH                output report
  --baseline PATH            compatible report to compare
  --threshold-percent N      regression threshold, default 10
  --fail-on-regression       exit 2 when any metric crosses the threshold

The full preset is intended for release decisions. The quick preset verifies
the harness and is useful during development, but is too short for a final
performance claim.
USAGE
    exit $status;
}

sub define_benchmark_classes () {
    my $framer_declaration;
    if (eval { require Linux::Event::Framer; 1 }) {
        $framer_declaration = q{use Linux::Event::Framer 'Delimiter', "\n";};
    } else {
        require Linux::Event::IO::Sock::Stream::Framer;
        $framer_declaration
            = q{use Linux::Event::IO::Sock::Stream::Framer 'Delimiter', "\n";};
    }

    my $source = qq{
        package Linux::Event::Bench::Regression::Raw;
        use parent -norequire, 'Linux::Event::IO::Sock::Stream';
        sub on_data (\$stream, \$bytes) { \$stream->write(\$bytes) }
        sub on_error (\$stream, \$error) { die "raw Stream error: \$error\\n" }

        package Linux::Event::Bench::Regression::Framed;
        use parent -norequire, 'Linux::Event::IO::Sock::Stream';
        $framer_declaration
        sub on_message (\$stream, \$message) { \$stream->send(\$message) }
        sub on_error (\$stream, \$error) { die "framed Stream error: \$error\\n" }

        package Linux::Event::Bench::Regression::DeadlineRaw;
        use parent -norequire, 'Linux::Event::Bench::Regression::Raw';
        sub stream_tuning (\$class) { return idle_timeout => 3_600 }

        package Linux::Event::Bench::Regression::Timer;
        use parent -norequire, 'Linux::Event::Kernel::Timer';
        sub on_timer (\$timer) { main::timer_expired(\$timer) }

        package Linux::Event::Bench::Regression::ConnectionServer;
        use parent -norequire, 'Linux::Event::IO::Sock::Stream';
        sub on_data (\$stream, \$bytes) { return }
        sub on_ready (\$stream) { main::connection_server_ready(\$stream) }
        sub on_error (\$stream, \$error) { die "server Stream error: \$error\\n" }

        package Linux::Event::Bench::Regression::ConnectionListener;
        use parent -norequire, 'Linux::Event::IO::Sock::Listener';
        sub on_error (\$listener, \$error) {
            die "Listener error: \$error\\n";
        }

        package Linux::Event::Bench::Regression::ConnectionClient;
        use parent -norequire, 'Linux::Event::IO::Sock::Stream';
        sub on_data (\$stream, \$bytes) { return }
        sub on_ready (\$stream) { main::connection_client_ready(\$stream) }
        sub on_error (\$stream, \$error) { die "client Stream error: \$error\\n" }
        1;
    };
    eval $source or die "define benchmark classes: $@";
    return;
}

sub rotated_workloads ($repeat) {
    my $offset = ($repeat - 1) % @workloads;
    return (@workloads[$offset .. $#workloads], @workloads[0 .. $offset - 1]);
}

sub run_workload ($name) {
    return registration_lifecycle() if $name eq 'registration-lifecycle';
    return timer_lifecycle() if $name eq 'timer-lifecycle';
    return timer_expiration() if $name eq 'timer-expiration';
    return stream_lifecycle('Linux::Event::Bench::Regression::Raw')
        if $name eq 'raw-stream-lifecycle';
    return stream_lifecycle('Linux::Event::Bench::Regression::Framed')
        if $name eq 'framed-stream-lifecycle';
    return stream_throughput('Linux::Event::Bench::Regression::Raw', 0)
        if $name eq 'raw-stream-throughput';
    return stream_throughput(
        'Linux::Event::Bench::Regression::DeadlineRaw', 0,
    ) if $name eq 'deadline-stream-throughput';
    return stream_throughput('Linux::Event::Bench::Regression::Framed', 1)
        if $name eq 'framed-stream-throughput';
    return connection_lifecycle();
}

sub registration_lifecycle () {
    my $loop = Linux::Event::Loop->new;
    my ($server, $client) = socket_pool($pool);
    register_churn($loop, $server, $warmup_iterations);
    my ($wall, $cpu) = timed(sub {
        register_churn($loop, $server, $iterations);
    });
    close $_ for @$server, @$client;
    return measurement($iterations, 'registration', $wall, $cpu);
}

sub register_churn ($loop, $handles, $count) {
    for my $i (0 .. $count - 1) {
        my $registration = $loop->watch(
            fh => $handles->[$i % @$handles],
            read => \&no_ready,
        );
        $registration->cancel;
    }
    return;
}

sub no_ready ($registration) { return }

sub timer_lifecycle () {
    my $loop = Linux::Event::Loop->new;
    timer_churn($loop, $warmup_iterations);
    my ($wall, $cpu) = timed(sub {
        timer_churn($loop, $iterations);
    });
    return measurement($iterations, 'timer', $wall, $cpu);
}

sub timer_churn ($loop, $count) {
    for (1 .. $count) {
        my $timer = $loop->add(
            Linux::Event::Bench::Regression::Timer->new(after => 3_600)
        );
        $timer->cancel;
    }
    return;
}

sub timer_expiration () {
    run_timer_expirations($warmup_iterations) if $warmup_iterations;
    my ($wall, $cpu) = run_timer_expirations($iterations);
    return measurement($iterations, 'timer', $wall, $cpu);
}

sub run_timer_expirations ($count) {
    my $loop = Linux::Event::Loop->new;
    my $run = {
        loop => $loop,
        target => $count,
        completed => 0,
    };
    for (1 .. $count) {
        $loop->add(Linux::Event::Bench::Regression::Timer->new(
            after => 0,
            data => $run,
        ));
    }
    my ($wall, $cpu) = timed(sub { $loop->run });
    die "timer expiration completed $run->{completed} of $count Timers\n"
        if $run->{completed} != $count;
    return ($wall, $cpu);
}

sub timer_expired ($timer) {
    my $run = $timer->data;
    $run->{completed}++;
    $run->{loop}->stop if $run->{completed} == $run->{target};
    return;
}

sub stream_lifecycle ($class) {
    my $loop = Linux::Event::Loop->new;
    my ($server, $client) = socket_pool($pool);
    stream_churn($loop, $class, $server, $warmup_iterations);
    my ($wall, $cpu) = timed(sub {
        stream_churn($loop, $class, $server, $iterations);
    });
    close $_ for @$server, @$client;
    return measurement($iterations, 'stream', $wall, $cpu);
}

sub stream_churn ($loop, $class, $handles, $count) {
    for my $i (0 .. $count - 1) {
        my $stream = $class->new(fh => $handles->[$i % @$handles]);
        $loop->add($stream);
        $stream->detach;
    }
    return;
}

sub socket_pool ($count) {
    my (@server, @client);
    for (1 .. $count) {
        socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
            or die "socketpair: $!\n";
        push @server, $a;
        push @client, $b;
    }
    return (\@server, \@client);
}

sub stream_throughput ($class, $framed) {
    my $loop = Linux::Event::Loop->new;
    my $payload = 'x' x 64;
    my $wire = $framed ? "$payload\n" : $payload;
    my $bench = {
        loop => $loop,
        phase => $warmup_messages ? 'warmup' : 'measure',
        clients => $clients,
        messages => $messages,
        warmup_messages => $warmup_messages,
        wire => $wire,
        wire_length => length($wire),
        warmup_ready => 0,
        measured_ready => 0,
        states => [],
        streams => [],
        registrations => [],
        client_handles => [],
    };

    for my $index (0 .. $clients - 1) {
        socketpair(my $server, my $client, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
            or die "socketpair: $!\n";
        my $stream = $class->new(loop => $loop, fh => $server);
        my $state = {
            bench => $bench,
            fh => $client,
            buffer => '',
            completed => 0,
        };
        my $registration = $loop->watch(
            fh => $client,
            data => $state,
            read => \&throughput_client_read,
        );
        push @{ $bench->{streams} }, $stream;
        push @{ $bench->{client_handles} }, $client;
        push @{ $bench->{states} }, $state;
        push @{ $bench->{registrations} }, $registration;
    }

    if ($warmup_messages) {
        write_wire($_) for @{ $bench->{states} };
    } else {
        begin_throughput_measurement($bench);
    }
    $loop->run;

    my $wall = $bench->{wall_end} - $bench->{wall_start};
    my $cpu = $bench->{cpu_end} - $bench->{cpu_start};
    $_->cancel for @{ $bench->{registrations} };
    $_->close for @{ $bench->{streams} };
    close $_ for @{ $bench->{client_handles} };
    return measurement($clients * $messages, 'message', $wall, $cpu);
}

sub throughput_client_read ($registration) {
    my $state = $registration->data;
    my $bench = $state->{bench};
    my $read = sysread($state->{fh}, my $chunk, 65_536);
    die "throughput client read: $!\n" if !defined $read;
    die "throughput peer closed early\n" if !$read;
    $state->{buffer} .= $chunk;

    while (length($state->{buffer}) >= $bench->{wire_length}) {
        my $message = substr(
            $state->{buffer}, 0, $bench->{wire_length}, '',
        );
        die "throughput payload mismatch\n" if $message ne $bench->{wire};
        $state->{completed}++;

        if ($bench->{phase} eq 'warmup') {
            if ($state->{completed} == $bench->{warmup_messages}) {
                $bench->{warmup_ready}++;
                begin_throughput_measurement($bench)
                    if $bench->{warmup_ready} == $bench->{clients};
            } else {
                write_wire($state);
            }
            next;
        }

        if ($state->{completed} == $bench->{messages}) {
            $bench->{measured_ready}++;
            if ($bench->{measured_ready} == $bench->{clients}) {
                $bench->{wall_end} = clock_gettime(CLOCK_MONOTONIC);
                $bench->{cpu_end}
                    = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
                $bench->{loop}->stop;
            }
        } else {
            write_wire($state);
        }
    }
    return;
}

sub begin_throughput_measurement ($bench) {
    $bench->{phase} = 'measure';
    $bench->{measured_ready} = 0;
    for my $state (@{ $bench->{states} }) {
        $state->{completed} = 0;
        die "warmup left a partial message\n" if length $state->{buffer};
    }
    $bench->{wall_start} = clock_gettime(CLOCK_MONOTONIC);
    $bench->{cpu_start} = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
    write_wire($_) for @{ $bench->{states} };
    return;
}

sub write_wire ($state) {
    my $wire = $state->{bench}{wire};
    my $written = syswrite($state->{fh}, $wire);
    die "throughput client write: $!\n" if !defined $written;
    die "throughput client short write\n" if $written != length($wire);
    return;
}

sub connection_lifecycle () {
    run_connections($warmup_connections) if $warmup_connections;
    my ($wall, $cpu) = run_connections($connections);
    return measurement($connections, 'connection', $wall, $cpu);
}

sub run_connections ($count) {
    my $loop = Linux::Event::Loop->new;
    $loop->enable_watcher_reclaim(1);
    my $run = {
        loop => $loop,
        connections => $count,
        concurrency => $clients < $count ? $clients : $count,
        started => 0,
        active => 0,
        client_done => 0,
        server_done => 0,
    };
    my $listener = Linux::Event::Bench::Regression::ConnectionListener->new(
        host => '127.0.0.1', port => 0,
        stream => {
            class => 'Linux::Event::Bench::Regression::ConnectionServer',
            data  => $run,
        },
    );
    $loop->add($listener);
    $run->{port} = $listener->port;

    my $wall_start = clock_gettime(CLOCK_MONOTONIC);
    my $cpu_start = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
    launch_connections($run);
    $loop->run;
    my $cpu = clock_gettime(CLOCK_PROCESS_CPUTIME_ID) - $cpu_start;
    my $wall = clock_gettime(CLOCK_MONOTONIC) - $wall_start;

    $listener->close;
    die "connection workload completed $run->{client_done} of $count clients\n"
        if $run->{client_done} != $count;
    die "connection workload accepted $run->{server_done} of $count peers\n"
        if $run->{server_done} != $count;
    return ($wall, $cpu);
}

sub launch_connections ($run) {
    while ($run->{active} < $run->{concurrency}
        && $run->{started} < $run->{connections}) {
        $run->{active}++;
        $run->{started}++;
        my $stream
            = Linux::Event::Bench::Regression::ConnectionClient->connect(
                host => '127.0.0.1',
                port => $run->{port},
                timeout => 30,
                data => $run,
            );
        $run->{loop}->add($stream);
    }
    return;
}

sub connection_server_ready ($stream) {
    my $run = $stream->data;
    $stream->close;
    $run->{server_done}++;
    finish_connections($run);
    return;
}

sub connection_client_ready ($stream) {
    my $run = $stream->data;
    setsockopt($stream->fh, SOL_SOCKET, SO_LINGER, pack('ii', 1, 0))
        or die "connection client SO_LINGER: $!\n";
    $stream->close;
    $run->{active}--;
    $run->{client_done}++;
    launch_connections($run);
    finish_connections($run);
    return;
}

sub finish_connections ($run) {
    $run->{loop}->stop
        if $run->{client_done} == $run->{connections}
        && $run->{server_done} == $run->{connections};
    return;
}

sub timed ($code) {
    my $wall_start = clock_gettime(CLOCK_MONOTONIC);
    my $cpu_start = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
    $code->();
    my $cpu = clock_gettime(CLOCK_PROCESS_CPUTIME_ID) - $cpu_start;
    my $wall = clock_gettime(CLOCK_MONOTONIC) - $wall_start;
    return ($wall, $cpu);
}

sub measurement ($operations, $unit, $wall, $cpu) {
    die "benchmark clock returned a non-positive duration\n"
        if $wall <= 0 || $cpu <= 0;
    return {
        operations => $operations,
        unit => $unit,
        elapsed_seconds => $wall,
        cpu_seconds => $cpu,
        operations_per_second => $operations / $wall,
        cpu_us_per_operation => $cpu * 1_000_000 / $operations,
    };
}

sub summarize ($records) {
    my @result;
    for my $workload (@workloads) {
        my @set = grep { $_->{workload} eq $workload } @$records;
        push @result, {
            workload => $workload,
            unit => $set[0]{unit},
            operations_per_second => median(
                map { $_->{operations_per_second} } @set
            ),
            cpu_us_per_operation => median(
                map { $_->{cpu_us_per_operation} } @set
            ),
        };
    }
    return @result;
}

sub median (@values) {
    @values = sort { $a <=> $b } @values;
    my $middle = int(@values / 2);
    return @values % 2
        ? $values[$middle]
        : ($values[$middle - 1] + $values[$middle]) / 2;
}

sub compare_reports ($baseline, $candidate) {
    die "baseline is not a performance-regression report\n"
        if ($baseline->{benchmark} // '') ne $candidate->{benchmark};
    die "baseline contract does not match candidate contract\n"
        if ($baseline->{benchmark_contract_version} // -1)
            != $candidate->{benchmark_contract_version};
    my $json = JSON::PP->new->canonical;
    die "baseline configuration does not match candidate configuration\n"
        if $json->encode($baseline->{configuration})
            ne $json->encode($candidate->{configuration});

    my %baseline = map { $_->{workload} => $_ } @{ $baseline->{summary} };
    my @comparison;
    for my $current (@{ $candidate->{summary} }) {
        my $before = $baseline{$current->{workload}}
            // die "baseline is missing workload $current->{workload}\n";
        my $rate_delta = percent_delta(
            $before->{operations_per_second},
            $current->{operations_per_second},
        );
        my $cpu_delta = percent_delta(
            $before->{cpu_us_per_operation},
            $current->{cpu_us_per_operation},
        );
        my $regression = $rate_delta <= -$threshold_percent
            || $cpu_delta >= $threshold_percent;
        push @comparison, {
            workload => $current->{workload},
            unit => $current->{unit},
            baseline_operations_per_second
                => $before->{operations_per_second},
            candidate_operations_per_second
                => $current->{operations_per_second},
            throughput_delta_percent => $rate_delta,
            baseline_cpu_us_per_operation
                => $before->{cpu_us_per_operation},
            candidate_cpu_us_per_operation
                => $current->{cpu_us_per_operation},
            cpu_delta_percent => $cpu_delta,
            regression => $regression ? JSON::PP::true : JSON::PP::false,
        };
    }
    return {
        baseline_version => $baseline->{linux_event_version},
        candidate_version => $candidate->{linux_event_version},
        threshold_percent => $threshold_percent,
        workloads => \@comparison,
    };
}

sub percent_delta ($before, $after) {
    die "cannot compare a zero baseline metric\n" if !$before;
    return ($after / $before - 1) * 100;
}

sub print_comparison ($comparison) {
    say "\nRegression comparison";
    say "baseline=$comparison->{baseline_version} "
        . "candidate=$comparison->{candidate_version} "
        . "threshold=$comparison->{threshold_percent}%";
    printf "%-30s %12s %12s %10s\n",
        'workload', 'rate delta', 'cpu delta', 'status';
    for my $row (@{ $comparison->{workloads} }) {
        printf "%-30s %+11.2f%% %+11.2f%% %10s\n",
            $row->{workload},
            $row->{throughput_delta_percent},
            $row->{cpu_delta_percent},
            $row->{regression} ? 'REGRESSION' : 'ok';
    }
    return;
}

sub environment_info () {
    my ($sysname, $nodename, $release, $version, $machine) = uname();
    my $cpu_model;
    if (open my $cpu, '<', '/proc/cpuinfo') {
        while (my $line = <$cpu>) {
            if ($line =~ /^model name\s*:\s*(.+?)\s*$/) {
                $cpu_model = $1;
                last;
            }
        }
        close $cpu;
    }
    return {
        perl => "$^V",
        perl_path => $^X,
        os => $sysname,
        kernel => $release,
        machine => $machine,
        hostname => $nodename,
        cpu_model => $cpu_model,
    };
}

sub read_json ($path) {
    open my $fh, '<', $path or die "open $path: $!\n";
    local $/;
    my $document = <$fh>;
    close $fh or die "close $path: $!\n";
    return JSON::PP->new->decode($document);
}

sub write_json ($path, $document) {
    my $dir = dirname($path);
    make_path($dir) if $dir ne '.' && !-d $dir;
    open my $fh, '>', $path or die "open $path: $!\n";
    print {$fh} JSON::PP->new->canonical->pretty->encode($document);
    close $fh or die "close $path: $!\n";
    return;
}
