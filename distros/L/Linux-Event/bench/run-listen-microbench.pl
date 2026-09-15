#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use Socket qw(
    AF_INET INADDR_LOOPBACK
    SOCK_STREAM SOCK_NONBLOCK SOCK_CLOEXEC
    SOL_SOCKET SO_LINGER SO_REUSEADDR
    pack_sockaddr_in unpack_sockaddr_in
);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);

use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::Loop;

my @modes = qw(manual add loop);
my @clients = (1, 10, 100);
my $connections = 10_000;
my $repeats = 9;
my $timeout = 30;
my $help = 0;

GetOptions(
    'modes=s'       => sub { @modes = split /,/, $_[1] },
    'clients=s'     => sub { @clients = map { 0 + $_ } split /,/, $_[1] },
    'connections=i' => \$connections,
    'repeats=i'     => \$repeats,
    'timeout=f'     => \$timeout,
    'help'          => \$help,
) or usage(1);
usage(0) if $help;

die "connections must be positive\n" if $connections < 1;
die "repeats must be positive\n" if $repeats < 1;
die "timeout must be positive\n" if $timeout <= 0;
die "clients must be positive\n" if grep { $_ < 1 } @clients;
my %valid_mode = map { $_ => 1 } qw(manual add loop);
die "modes must contain only manual, add, or loop\n"
    if grep { !$valid_mode{$_} } @modes;
my %seen_mode;
die "modes must not contain duplicates\n"
    if grep { $seen_mode{$_}++ } @modes;

{
    package BenchAutomaticStream;
    use parent 'Linux::Event::IO::Sock::Stream';

    sub on_data ($stream, $bytes) { }

    sub on_ready ($stream) {
        my $run = $stream->data;
        $stream->close;
        $run->{accepted}++;
        main::finish_if_done($run);
    }

}

{
    package BenchAutomaticListener;
    use parent 'Linux::Event::IO::Sock::Listener';

    sub on_error ($listener, $error) {
        die "benchmark listener failed: $error\n";
    }
}

{
    package BenchListenClient;
    use parent 'Linux::Event::IO::Sock::Stream';

    sub on_data ($stream, $bytes) { }

    sub on_ready ($stream) {
        my $run = $stream->data;
        main::enable_abortive_close($stream->fh, 'client');
        $stream->close;
        $run->{active}--;
        $run->{completed}++;
        main::launch_requests($run);
        main::finish_if_done($run);
    }

    sub on_error ($stream, $error) {
        die "benchmark connection failed: $error\n";
    }
}

sub enable_abortive_close ($fh, $role) {
    setsockopt($fh, SOL_SOCKET, SO_LINGER, pack('ii', 1, 0))
        or die "$role SO_LINGER: $!\n";
    return;
}

sub finish_if_done ($run) {
    $run->{loop}->stop
        if $run->{accepted} == $run->{connections}
            && $run->{completed} == $run->{connections};
    return;
}

sub manual_accept_ready ($registration) {
    my $run = $registration->data;
    while (accept(my $client, $run->{listener_fh})) {
        close $client;
        $run->{accepted}++;
    }
    die "manual accept failed: $!\n"
        if !$!{EAGAIN} && !$!{EWOULDBLOCK};
    finish_if_done($run);
    return;
}

sub launch_requests ($run) {
    while ($run->{active} < $run->{clients}
        && $run->{started} < $run->{connections}) {
        $run->{started}++;
        $run->{active}++;
        BenchListenClient->connect(
            loop    => $run->{loop},
            host    => '127.0.0.1',
            port    => $run->{port},
            timeout => $timeout,
            data    => $run,
        );
    }
    return;
}

sub one_run ($mode, $client_count) {
    my $loop = Linux::Event::Loop->new;
    $loop->enable_watcher_reclaim(1);
    my $run = {
        mode        => $mode,
        clients     => $client_count,
        connections => $connections,
        loop        => $loop,
        started     => 0,
        active      => 0,
        completed   => 0,
        accepted    => 0,
    };
    if ($mode eq 'manual') {
        socket(my $listener, AF_INET,
            SOCK_STREAM | SOCK_NONBLOCK | SOCK_CLOEXEC, 0)
            or die "manual listener socket: $!\n";
        setsockopt($listener, SOL_SOCKET, SO_REUSEADDR, pack('i', 1))
            or die "manual listener setsockopt: $!\n";
        bind($listener, pack_sockaddr_in(0, INADDR_LOOPBACK))
            or die "manual listener bind: $!\n";
        listen($listener, 4096) or die "manual listener listen: $!\n";
        ($run->{port}) = unpack_sockaddr_in(getsockname($listener));
        $run->{listener_fh} = $listener;
        $run->{listener_watcher} = $loop->watch(
            fh   => $listener,
            data => $run,
            read => \&manual_accept_ready,
        );
    } elsif ($mode eq 'add') {
        $run->{listener} = BenchAutomaticListener->new(
            stream => {
                class => 'BenchAutomaticStream',
                data  => $run,
            },
            host => '127.0.0.1', port => 0,
        );
        $loop->add($run->{listener});
        $run->{port} = $run->{listener}->port;
    } else {
        $run->{listener} = BenchAutomaticListener->new(
            stream => {
                class => 'BenchAutomaticStream',
                data  => $run,
            },
            loop => $loop, host => '127.0.0.1', port => 0,
        );
        $run->{port} = $run->{listener}->port;
    }

    my $wall_start = clock_gettime(CLOCK_MONOTONIC);
    my ($user_start, $system_start) = (times)[0, 1];
    launch_requests($run);
    $loop->run;
    my ($user_end, $system_end) = (times)[0, 1];
    my $elapsed = clock_gettime(CLOCK_MONOTONIC) - $wall_start;
    my $cpu = ($user_end - $user_start) + ($system_end - $system_start);

    if ($mode eq 'manual') {
        $run->{listener_watcher}->cancel;
        close $run->{listener_fh};
    } else {
        $run->{listener}->close;
    }
    return {
        rate   => $connections / $elapsed,
        cpu_us => $cpu * 1_000_000 / $connections,
    };
}

sub median (@values) {
    @values = sort { $a <=> $b } @values;
    my $middle = int(@values / 2);
    return @values % 2
        ? $values[$middle]
        : ($values[$middle - 1] + $values[$middle]) / 2;
}

say 'Median loopback TCP Listener lifecycle benchmark';
say "Linux::Event version $Linux::Event::IO::Sock::Listener::VERSION";
printf "%-8s %8s %14s %14s\n",
    qw(mode clients accepts/s cpu_us/accept);
for my $client_count (@clients) {
    my %result;
    for my $repeat (0 .. $repeats - 1) {
        my $offset = $repeat % @modes;
        my @order = (@modes[$offset .. $#modes], @modes[0 .. $offset - 1]);
        push @{ $result{$_} }, one_run($_, $client_count) for @order;
    }
    for my $mode (@modes) {
        printf "%-8s %8d %14.1f %14.3f\n",
            $mode,
            $client_count,
            median(map { $_->{rate} } @{ $result{$mode} }),
            median(map { $_->{cpu_us} } @{ $result{$mode} });
    }
}

sub usage ($exit) {
    print <<'USAGE';
Usage: perl -Mblib bench/run-listen-microbench.pl [options]

  --modes=LIST          manual,add,loop (default: all three)
  --clients=LIST        concurrent clients (default: 1,10,100)
  --connections=N       accepted connections per row (default: 10000)
  --repeats=N           median repetitions (default: 9)
  --timeout=SECONDS     catastrophic connection deadline (default: 30)
  --help

All rows acquire loopback TCP clients through MySocket->connect. Manual uses
explicit listener setup, Loop->watch, Perl accept, and close. Add uses detached
Listener construction followed by Loop->add. Loop supplies loop => directly to
Listener->new. Both Listener rows construct and close the same minimal Stream
subclass. Every successfully connected client
uses equal abortive teardown so repeated rows do not exhaust the host with
client-side TIME_WAIT sockets. Repeat execution order rotates to reduce bias;
use a repeat count divisible by three for balanced execution order.
USAGE
    exit $exit;
}
