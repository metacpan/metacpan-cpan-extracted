#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use Time::HiRes qw(time clock_gettime CLOCK_PROCESS_CPUTIME_ID);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

{
    package Linux::Event::Bench::RawEchoStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) {
        $stream->write($bytes)
            or die "microbenchmark unexpectedly hit Stream backpressure\n";
    }
    sub on_error ($stream, $error) { die "Stream error: $error\n" }
}

{
    package Linux::Event::Bench::CappedRawEchoStream;
    use parent -norequire, 'Linux::Event::Bench::RawEchoStream';
    sub stream_tuning ($class) { return max_pending_bytes => 16 * 1024 * 1024 }
}

{
    package Linux::Event::Bench::DeadlineRawEchoStream;
    use parent -norequire, 'Linux::Event::Bench::RawEchoStream';
    sub stream_tuning ($class) { return idle_timeout => 3_600 }
}

my @clients = (1, 10, 100, 1000);
my $messages = 100;
my $warmup = 10;
my $bytes = 64;
my $repeats = 6;

GetOptions(
    'clients=s'  => sub { @clients = split /,/, $_[1] },
    'messages=i' => \$messages,
    'warmup=i'   => \$warmup,
    'bytes=i'    => \$bytes,
    'repeats=i'  => \$repeats,
) or die "bad options\n";

die "messages must be > 0\n" if $messages <= 0;
die "warmup must be >= 0\n" if $warmup < 0;
die "bytes must be > 0\n" if $bytes <= 0;
die "repeats must be > 0\n" if $repeats <= 0;

my @systems = (
    'raw-reactor',
    'subclass-stream',
    'subclass-stream-deadline',
    'subclass-stream-capped',
);
my @rows;

for my $count (@clients) {
    die "client count must be > 0\n" if $count <= 0;

    for my $repeat (1 .. $repeats) {
        # Balanced cyclic rotation. Any multiple of the system count
        # repeats places each implementation in each execution position equally.
        my $shift = ($repeat - 1) % @systems;
        my @order = (@systems[$shift .. $#systems], @systems[0 .. $shift - 1]);
        for my $system (@order) {
            my $r = run_case($system, $count);
            $r->{repeat} = $repeat;
            push @rows, $r;
            printf "%s clients=%d repeat=%d %.1f msg/s cpu=%.3f us/msg\n",
                $system, $count, $repeat,
                $r->{messages_per_second}, $r->{cpu_us_per_message};
        }
    }
}

say "\nMedian Stream microbenchmark";
printf "%-18s %8s %14s %14s\n", 'system', 'clients', 'msg/s', 'cpu us/msg';
for my $count (@clients) {
    for my $system (@systems) {
        my @set = grep { $_->{clients} == $count && $_->{system} eq $system } @rows;
        my $rate = median(map { $_->{messages_per_second} } @set);
        my $cpu  = median(map { $_->{cpu_us_per_message} } @set);
        printf "%-18s %8d %14.1f %14.3f\n", $system, $count, $rate, $cpu;
    }
}

say "\nThis is a same-process AF_UNIX development microbenchmark, not the final";
say "cross-runtime Stream leaderboard. It compares direct raw-reactor echo";
say "with uncapped, deadline-tracked, and hard-capped subclass Streams.";

sub run_case ($system, $count) {
    my $loop = Linux::Event::Loop->new;
    my $payload = 'x' x $bytes;

    my @server_fh;
    my @client_fh;
    my @server_obj;
    my @client_watchers;
    my @client_state;

    my $bench = {
        loop => $loop,
        payload => $payload,
        clients => $count,
        warmup => $warmup,
        messages => $messages,
        warmup_done => 0,
        measured_done => 0,
        phase => $warmup ? 'warmup' : 'measure',
        wall_start => undef,
        cpu_start => undef,
        wall_end => undef,
        cpu_end => undef,
    };

    for my $i (0 .. $count - 1) {
        socketpair(my $server, my $client, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
            or die "socketpair: $!";
        set_nonblocking($server);
        set_nonblocking($client);
        push @server_fh, $server;
        push @client_fh, $client;

        if ($system eq 'raw-reactor') {
            my $w = $loop->watch(
                fh => $server,
                read => \&_raw_server_read,
            );
            push @server_obj, $w;
        } else {
            my $class = $system eq 'subclass-stream-capped'
                ? 'Linux::Event::Bench::CappedRawEchoStream'
                : $system eq 'subclass-stream-deadline'
                    ? 'Linux::Event::Bench::DeadlineRawEchoStream'
                    : 'Linux::Event::Bench::RawEchoStream';
            my $s = $class->new(
                loop => $loop,
                fh   => $server,
            );
            push @server_obj, $s;
        }

        my $state = {
            bench => $bench,
            fh => $client,
            buffer => '',
            completed => 0,
            warmup_complete => 0,
            measured_complete => 0,
        };
        push @client_state, $state;

        my $cw = $loop->watch(
            fh => $client,
            data => $state,
            read => \&_client_read,
        );
        push @client_watchers, $cw;
    }

    $bench->{client_state} = \@client_state;

    if ($warmup) {
        syswrite_all($_->{fh}, $payload) for @client_state;
    } else {
        start_measurement($bench);
    }

    $loop->run;

    my $elapsed = $bench->{wall_end} - $bench->{wall_start};
    my $cpu = $bench->{cpu_end} - $bench->{cpu_start};
    my $total = $count * $messages;

    # Explicit cleanup; Stream owns server fhs, raw watcher cases do not.
    for my $obj (@server_obj) {
        if ($system eq 'raw-reactor') {
            $obj->cancel;
        } else {
            $obj->close if !$obj->is_closed;
        }
    }
    $_->cancel for @client_watchers;
    close $_ for @client_fh;
    if ($system eq 'raw-reactor') {
        close $_ for @server_fh;
    }

    return {
        system => $system,
        clients => $count,
        messages => $total,
        elapsed_seconds => $elapsed,
        cpu_seconds => $cpu,
        messages_per_second => $total / $elapsed,
        cpu_us_per_message => ($cpu * 1_000_000) / $total,
    };
}

sub _raw_server_read ($watcher) {
    my $fh = $watcher->fh;
    while (1) {
        my $buf = '';
        my $n = sysread($fh, $buf, 65_536);
        if (defined $n) {
            return if $n == 0;
            syswrite_all($fh, $buf);
            next;
        }
        return if $!{EAGAIN} || $!{EWOULDBLOCK};
        next if $!{EINTR};
        die "raw server read: $!";
    }
}

sub _client_read ($watcher) {
    my $state = $watcher->data;
    my $bench = $state->{bench};
    my $fh = $state->{fh};

    while (1) {
        my $chunk = '';
        my $n = sysread($fh, $chunk, 65_536);
        if (defined $n) {
            die "client unexpected EOF\n" if $n == 0;
            $state->{buffer} .= $chunk;

            while (length($state->{buffer}) >= $bytes) {
                substr($state->{buffer}, 0, $bytes, '');
                $state->{completed}++;

                if ($bench->{phase} eq 'warmup') {
                    if ($state->{completed} < $warmup) {
                        syswrite_all($fh, $bench->{payload});
                    } elsif (!$state->{warmup_complete}++) {
                        $bench->{warmup_done}++;
                        start_measurement($bench)
                            if $bench->{warmup_done} == $bench->{clients};
                    }
                } else {
                    if ($state->{completed} < $messages) {
                        syswrite_all($fh, $bench->{payload});
                    } elsif (!$state->{measured_complete}++) {
                        $bench->{measured_done}++;
                        if ($bench->{measured_done} == $bench->{clients}) {
                            $bench->{wall_end} = time;
                            $bench->{cpu_end} = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
                            $bench->{loop}->stop;
                            return;
                        }
                    }
                }
            }
            next;
        }

        return if $!{EAGAIN} || $!{EWOULDBLOCK};
        next if $!{EINTR};
        die "client read: $!";
    }
}

sub start_measurement ($bench) {
    return if $bench->{phase} eq 'measure' && defined $bench->{wall_start};
    $bench->{phase} = 'measure';

    for my $state (@{ $bench->{client_state} }) {
        $state->{completed} = 0;
        $state->{buffer} = '';
    }

    $bench->{cpu_start} = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
    $bench->{wall_start} = time;
    syswrite_all($_->{fh}, $bench->{payload}) for @{ $bench->{client_state} };
}

sub syswrite_all ($fh, $bytes) {
    my $off = 0;
    my $len = length($bytes);
    while ($off < $len) {
        my $n = syswrite($fh, $bytes, $len - $off, $off);
        if (defined $n) {
            $off += $n;
            next;
        }
        next if $!{EINTR};
        die "benchmark write would block unexpectedly\n" if $!{EAGAIN} || $!{EWOULDBLOCK};
        die "benchmark write: $!";
    }
}

sub set_nonblocking ($fh) {
    my $flags = fcntl($fh, F_GETFL, 0);
    die "fcntl F_GETFL: $!" if !defined $flags;
    fcntl($fh, F_SETFL, $flags | O_NONBLOCK)
        or die "fcntl F_SETFL: $!";
}

sub median (@values) {
    @values = sort { $a <=> $b } @values;
    my $n = @values;
    return 0 if !$n;
    return $values[int($n / 2)] if $n % 2;
    return ($values[$n / 2 - 1] + $values[$n / 2]) / 2;
}
