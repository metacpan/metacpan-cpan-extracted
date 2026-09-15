#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use Getopt::Long qw(GetOptions);
use JSON::PP ();
use POSIX qw(strftime uname);
use Socket qw(SOL_SOCKET SO_LINGER);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);

use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::Loop;

my @styles = qw(subclass_method listener_shared_closure fresh_closure);
my $clients = 100;
my $connections = 10_000;
my $repeats = 9;
my $timeout = 30;
my $json_path;
my $help;

GetOptions(
    'styles=s' => sub { @styles = split /,/, $_[1] },
    'clients=i' => \$clients,
    'connections=i' => \$connections,
    'repeats=i' => \$repeats,
    'timeout=f' => \$timeout,
    'json=s' => \$json_path,
    'help' => \$help,
) or usage(2);
usage(0) if $help;

my %known = map { $_ => 1 } qw(
    subclass_method listener_shared_closure fresh_closure
);
die "unknown callback style: $_\n" for grep { !$known{$_} } @styles;
die "callback styles must not repeat\n"
    if do { my %seen; grep { $seen{$_}++ } @styles };
die "clients must be positive\n" if $clients < 1;
die "connections must be positive\n" if $connections < 1;
die "repeats must be positive\n" if $repeats < 1;
die "timeout must be positive\n" if $timeout <= 0;

our $FRESH_CLOSURES = 0;
our $SHARED_CALLBACK = sub ($stream, $bytes) { return };

{
    package Linux::Event::Bench::CallbackMethodStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { return }
    sub on_ready ($stream) { main::accepted_ready($stream) }
}

{
    package Linux::Event::Bench::CallbackClosureStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_ready ($stream) { main::accepted_ready($stream) }
}

{
    package Linux::Event::Bench::CallbackFreshStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { return }
    sub new ($class, %option) {
        $main::FRESH_CLOSURES++;
        $option{on_data} = sub ($stream, $bytes) { return };
        return $class->SUPER::new(%option);
    }
    sub on_ready ($stream) { main::accepted_ready($stream) }
}

{
    package Linux::Event::Bench::CallbackListener;
    use parent 'Linux::Event::IO::Sock::Listener';
    sub on_error ($listener, $error) {
        die "benchmark listener failed: $error\n";
    }
}

{
    package Linux::Event::Bench::CallbackClient;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { return }
    sub on_ready ($stream) {
        my $run = $stream->data;
        main::abortive_close($stream->fh);
        $stream->close;
        $run->{active}--;
        $run->{completed}++;
        main::launch_clients($run);
        main::finish_if_done($run);
    }
    sub on_error ($stream, $error) {
        die "benchmark client failed: $error\n";
    }
}

sub abortive_close ($fh) {
    setsockopt($fh, SOL_SOCKET, SO_LINGER, pack('ii', 1, 0))
        or die "client SO_LINGER: $!\n";
}

sub accepted_ready ($stream) {
    my $run = $stream->data;
    $stream->close;
    $run->{accepted}++;
    finish_if_done($run);
}

sub finish_if_done ($run) {
    $run->{loop}->stop
        if $run->{accepted} == $connections
        && $run->{completed} == $connections;
}

sub launch_clients ($run) {
    while ($run->{active} < $clients && $run->{started} < $connections) {
        $run->{active}++;
        $run->{started}++;
        Linux::Event::Bench::CallbackClient->connect(
            loop => $run->{loop},
            host => '127.0.0.1', port => $run->{port},
            timeout => $timeout, data => $run,
        );
    }
}

sub run_style ($style, $repeat) {
    my $loop = Linux::Event::Loop->new;
    $loop->enable_watcher_reclaim(1);
    my $run = {
        loop => $loop, started => 0, active => 0,
        completed => 0, accepted => 0,
    };
    my ($stream_class, %callback);
    if ($style eq 'subclass_method') {
        $stream_class = 'Linux::Event::Bench::CallbackMethodStream';
    } elsif ($style eq 'listener_shared_closure') {
        $stream_class = 'Linux::Event::Bench::CallbackClosureStream';
        $callback{on_data} = $SHARED_CALLBACK;
    } else {
        $stream_class = 'Linux::Event::Bench::CallbackFreshStream';
    }

    my $fresh_before = $FRESH_CLOSURES;
    my $listener = Linux::Event::Bench::CallbackListener->new(
        loop => $loop, host => '127.0.0.1', port => 0,
        stream => {
            class => $stream_class,
            data  => $run,
            %callback,
        },
    );
    $run->{port} = $listener->port;

    my $wall_start = clock_gettime(CLOCK_MONOTONIC);
    my ($user_start, $system_start) = (times)[0, 1];
    launch_clients($run);
    $loop->run;
    my ($user_end, $system_end) = (times)[0, 1];
    my $elapsed = clock_gettime(CLOCK_MONOTONIC) - $wall_start;
    my $cpu = ($user_end - $user_start) + ($system_end - $system_start);
    $listener->close;

    return {
        style => $style,
        repeat => $repeat,
        accepted => $run->{accepted},
        elapsed_seconds => $elapsed,
        parent_cpu_seconds => $cpu,
        accepts_per_second => $connections / $elapsed,
        parent_cpu_us_per_accept => $cpu * 1_000_000 / $connections,
        fresh_closures_created => $FRESH_CLOSURES - $fresh_before,
    };
}

sub median (@value) {
    @value = sort { $a <=> $b } @value;
    my $middle = int(@value / 2);
    return @value % 2 ? $value[$middle]
        : ($value[$middle - 1] + $value[$middle]) / 2;
}

sub paired_delta ($rows, $style, $field) {
    my %baseline = map {
        $_->{repeat} => $_->{$field}
    } grep { $_->{style} eq 'subclass_method' } @$rows;
    my @delta = map {
        100 * ($_->{$field} / $baseline{$_->{repeat}} - 1)
    } grep {
        $_->{style} eq $style && $baseline{$_->{repeat}}
    } @$rows;
    return @delta ? median(@delta) : undef;
}

say 'Accepted Stream first-class callback construction benchmark';
say "clients=$clients connections=$connections repeats=$repeats";
my @row;
for my $repeat (1 .. $repeats) {
    my $shift = ($repeat - 1) % @styles;
    my @order = (@styles[$shift .. $#styles], @styles[0 .. $shift - 1]);
    for my $style (@order) {
        my $row = run_style($style, $repeat);
        push @row, $row;
        printf "%s repeat=%d %.1f accepts/s cpu=%.3f us/accept fresh=%d\n",
            $style, $repeat, $row->{accepts_per_second},
            $row->{parent_cpu_us_per_accept}, $row->{fresh_closures_created};
    }
}

my @summary;
say "\nPaired median summary";
printf "%-28s %14s %16s %12s %12s\n",
    'style', 'accepts/s', 'cpu us/accept', 'speed delta', 'cpu delta';
for my $style (@styles) {
    my @set = grep { $_->{style} eq $style } @row;
    my $speed_delta = $style eq 'subclass_method'
        ? undef : paired_delta(\@row, $style, 'accepts_per_second');
    my $cpu_delta = $style eq 'subclass_method'
        ? undef : paired_delta(\@row, $style, 'parent_cpu_us_per_accept');
    my $summary = {
        style => $style,
        accepts_per_second => median(map { $_->{accepts_per_second} } @set),
        parent_cpu_us_per_accept => median(
            map { $_->{parent_cpu_us_per_accept} } @set
        ),
        throughput_delta_percent => $speed_delta,
        parent_cpu_delta_percent => $cpu_delta,
    };
    push @summary, $summary;
    printf "%-28s %14.1f %16.3f %11s%% %11s%%\n",
        $style, $summary->{accepts_per_second},
        $summary->{parent_cpu_us_per_accept},
        defined($speed_delta) ? sprintf('%.2f', $speed_delta) : 'baseline',
        defined($cpu_delta) ? sprintf('%.2f', $cpu_delta) : 'baseline';
}

if (defined $json_path) {
    my ($sysname, undef, $release, $version, $machine) = uname();
    my $report = {
        benchmark => 'linux-event-first-class-callback-construction',
        benchmark_contract_version => 1,
        generated_at => strftime('%Y-%m-%dT%H:%M:%SZ', gmtime),
        environment => {
            linux_event_version => $Linux::Event::IO::Sock::Stream::VERSION,
            perl_version => "$^V", os => $^O,
            uname => { sysname => $sysname, release => $release,
                version => $version, machine => $machine },
        },
        configuration => { clients => $clients, connections => $connections,
            repeats => $repeats, styles => \@styles },
        raw => \@row,
        summary => \@summary,
        notes => [
            'Parent process CPU per accept is the primary construction metric.',
            'listener_shared_closure passes one Listener-held CV to every accepted Stream.',
            'fresh_closure deliberately uses a benchmark-only new wrapper to allocate one CV per accepted Stream.',
        ],
    };
    my $directory = dirname($json_path);
    make_path($directory) if $directory ne '.' && !-d $directory;
    open my $output, '>', $json_path or die "open $json_path: $!\n";
    print {$output} JSON::PP->new->canonical->pretty->encode($report);
    close $output or die "close $json_path: $!\n";
    say "\nWrote $json_path";
}

sub usage ($status) {
    my $fh = $status ? *STDERR : *STDOUT;
    print {$fh} <<'USAGE';
Usage: perl -Mblib bench/run-first-class-callback-construction-bench.pl [options]

  --styles=LIST       subclass_method,listener_shared_closure,fresh_closure
  --clients=N         concurrent clients (default: 100)
  --connections=N     accepted connections per row (default: 10000)
  --repeats=N         paired repetitions (default: 9)
  --timeout=SECONDS   catastrophic client deadline (default: 30)
  --json=PATH         write raw rows and paired summary as JSON
  --help

Run order rotates within each repeat. The fresh-closure case is deliberately a
diagnostic; production Listener propagation reuses one callback CV.
USAGE
    exit $status;
}
