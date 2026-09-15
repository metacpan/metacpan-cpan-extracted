#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Fcntl qw(F_GETFD F_SETFD FD_CLOEXEC);
use Getopt::Long qw(GetOptions);
use JSON::PP;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC CLOCK_PROCESS_CPUTIME_ID);

use Linux::Event;
use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;

my @payload_sizes = (16, 4_096, 65_536);
my @idle_connections = (0, 63);
my $target_mib = 16;
my $minimum_messages = 512;
my $repeats = 7;
my $warmup = 1;
my $json_path;
my $help;

GetOptions(
    'payload-sizes=s' => sub {
        @payload_sizes = map { 0 + $_ } split /,/, $_[1];
    },
    'idle-connections=s' => sub {
        @idle_connections = map { 0 + $_ } split /,/, $_[1];
    },
    'target-mib=f'      => \$target_mib,
    'minimum-messages=i' => \$minimum_messages,
    'repeats=i'         => \$repeats,
    'warmup=i'          => \$warmup,
    'json=s'            => \$json_path,
    'help'              => \$help,
) or usage(1);
usage(0) if $help;

die "payload sizes must be positive\n" if grep { $_ < 1 } @payload_sizes;
die "idle connection counts must be non-negative\n"
    if grep { $_ < 0 } @idle_connections;
die "target-mib must be positive\n" if $target_mib <= 0;
die "minimum-messages must be positive\n" if $minimum_messages < 1;
die "repeats must be positive\n" if $repeats < 1;
die "warmup must be non-negative\n" if $warmup < 0;

{
    package Linux::Event::Bench::CachedClosureStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\n";

    our ($CAPTURE_A, $CAPTURE_B, $CAPTURE_C, $CAPTURE_D) = (1, 2, 3, 4);

    sub stream_tuning ($class) {
        return read_size => 65_536;
    }

    sub on_message ($stream, $message) {
        if ($message eq '') {
            $CAPTURE_A += $CAPTURE_B + $CAPTURE_C + $CAPTURE_D;
        }
        my $state = $stream->data;
        die "payload mismatch\n" if $message ne $state->{payload};
        $state->{messages}++;
        $state->{loop}->stop
            if $state->{messages} == $state->{expected_messages};
        return;
    }

    sub on_error ($stream, $error) {
        die "Stream error: $error\n";
    }
}

our ($PLAIN_A, $PLAIN_B, $PLAIN_C, $PLAIN_D) = (1, 2, 3, 4);

my $plain_coderef = sub ($stream, $message) {
    if ($message eq '') {
        $PLAIN_A += $PLAIN_B + $PLAIN_C + $PLAIN_D;
    }
    my $state = $stream->data;
    die "payload mismatch\n" if $message ne $state->{payload};
    $state->{messages}++;
    $state->{loop}->stop
        if $state->{messages} == $state->{expected_messages};
    return;
};

sub closure_one () {
    my $capture_a = 1;
    return sub ($stream, $message) {
        if ($message eq '') {
            $capture_a += $PLAIN_B + $PLAIN_C + $PLAIN_D;
        }
        my $state = $stream->data;
        die "payload mismatch\n" if $message ne $state->{payload};
        $state->{messages}++;
        $state->{loop}->stop
            if $state->{messages} == $state->{expected_messages};
        return;
    };
}

sub closure_four () {
    my ($capture_a, $capture_b, $capture_c, $capture_d) = (1, 2, 3, 4);
    return sub ($stream, $message) {
        if ($message eq '') {
            $capture_a += $capture_b + $capture_c + $capture_d;
        }
        my $state = $stream->data;
        die "payload mismatch\n" if $message ne $state->{payload};
        $state->{messages}++;
        $state->{loop}->stop
            if $state->{messages} == $state->{expected_messages};
        return;
    };
}

my @case = (
    { name => 'subclass_method', callback => sub { return undef } },
    { name => 'constructor_coderef', callback => sub { return $plain_coderef } },
    { name => 'closure_one', callback => \&closure_one },
    { name => 'closure_four', callback => \&closure_four },
);

my @configuration;
for my $payload_size (@payload_sizes) {
    my $target_bytes = int($target_mib * 1_048_576);
    my $messages = int($target_bytes / $payload_size);
    $messages = $minimum_messages if $messages < $minimum_messages;
    push @configuration, map {
        +{
            payload_size => $payload_size,
            idle_connections => $_,
            messages => $messages,
        }
    } @idle_connections;
}

for (1 .. $warmup) {
    for my $config (@configuration) {
        my $warm_messages = int($config->{messages} / 10);
        $warm_messages = 100 if $warm_messages < 100;
        $warm_messages = $config->{messages}
            if $warm_messages > $config->{messages};
        for my $case (@case) {
            run_case($case, { %$config, messages => $warm_messages });
        }
    }
}

my @raw;
for my $repeat (1 .. $repeats) {
    for my $config_index (0 .. $#configuration) {
        my $config = $configuration[$config_index];
        my @ordered = rotate_cases(
            \@case, $repeat - 1 + $config_index,
        );
        for my $case (@ordered) {
            my $row = run_case($case, $config);
            $row->{repeat} = $repeat;
            push @raw, $row;
            printf "%s bytes=%d idle=%d repeat=%d %.1f msg/s %.3f cpu us/msg\n",
                $case->{name}, $config->{payload_size},
                $config->{idle_connections}, $repeat,
                $row->{messages_per_second}, $row->{cpu_us_per_message};
        }
    }
}

my @summary;
for my $config (@configuration) {
    for my $case (@case) {
        my @rows = grep {
            $_->{case} eq $case->{name}
                && $_->{payload_size} == $config->{payload_size}
                && $_->{idle_connections} == $config->{idle_connections}
        } @raw;
        my $summary = {
            case => $case->{name},
            payload_size => $config->{payload_size},
            idle_connections => $config->{idle_connections},
            messages => $config->{messages},
            median_messages_per_second => median(
                map { $_->{messages_per_second} } @rows,
            ),
            median_cpu_us_per_message => median(
                map { $_->{cpu_us_per_message} } @rows,
            ),
            median_setup_us_per_stream => median(
                map { $_->{setup_us_per_stream} } @rows,
            ),
            median_rss_after_setup_kib => median(
                map { $_->{rss_after_setup_kib} } @rows,
            ),
        };
        if ($case->{name} ne 'subclass_method') {
            my (@throughput_delta, @cpu_delta);
            for my $row (@rows) {
                my ($paired_method) = grep {
                    $_->{case} eq 'subclass_method'
                        && $_->{payload_size} == $config->{payload_size}
                        && $_->{idle_connections}
                            == $config->{idle_connections}
                        && $_->{repeat} == $row->{repeat}
                } @raw;
                push @throughput_delta, 100 * (
                    $row->{messages_per_second}
                        / $paired_method->{messages_per_second} - 1
                );
                push @cpu_delta, 100 * (
                    $row->{cpu_us_per_message}
                        / $paired_method->{cpu_us_per_message} - 1
                );
            }
            $summary->{throughput_delta_percent} = median(@throughput_delta);
            $summary->{cpu_delta_percent} = median(@cpu_delta);
        }
        push @summary, $summary;
    }
}

say "\nFirst-class framed callback dispatch benchmark";
printf "target_mib=%.3f minimum_messages=%d warmup=%d repeats=%d\n",
    $target_mib, $minimum_messages, $warmup, $repeats;
printf "%-20s %8s %6s %12s %12s %10s %10s\n",
    'case', 'bytes', 'idle', 'msg/s', 'cpu us/msg', 'speed', 'cpu';
for my $row (@summary) {
    printf "%-20s %8d %6d %12.1f %12.3f %9s %9s\n",
        $row->{case}, $row->{payload_size}, $row->{idle_connections},
        $row->{median_messages_per_second},
        $row->{median_cpu_us_per_message},
        defined($row->{throughput_delta_percent})
            ? sprintf('%+.2f%%', $row->{throughput_delta_percent}) : '-',
        defined($row->{cpu_delta_percent})
            ? sprintf('%+.2f%%', $row->{cpu_delta_percent}) : '-';
}

if (defined $json_path) {
    my $report = {
        benchmark => 'linux-event-first-class-framed-callback-dispatch',
        benchmark_contract_version => 2,
        linux_event_version => $Linux::Event::VERSION,
        perl_version => 0 + $],
        configuration => {
            payload_sizes => \@payload_sizes,
            idle_connections => \@idle_connections,
            target_mib => 0 + $target_mib,
            minimum_messages => $minimum_messages,
            repeats => $repeats,
            warmup => $warmup,
            framer => 'Delimiter',
            delimiter_bytes => 1,
            read_size => 65_536,
        },
        raw => \@raw,
        summary => \@summary,
    };
    open my $json, '>', $json_path or die "open $json_path: $!\n";
    print {$json} JSON::PP->new->canonical->pretty->encode($report);
    close $json or die "close $json_path: $!\n";
}

sub run_case ($case, $config) {
    socketpair(my $receiver, my $sender,
        AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
    pipe(my $gate_read, my $gate_write) or die "gate pipe: $!";

    my $payload = 'x' x $config->{payload_size};
    my $wire = $payload . "\n";
    my $writer = fork();
    die "writer fork: $!" if !defined $writer;
    if ($writer == 0) {
        close $receiver;
        close $gate_write;
        my $gate = '';
        sysread($gate_read, $gate, 1) == 1 or exit 2;
        close $gate_read;
        local $SIG{PIPE} = 'IGNORE';
        eval { write_frames($sender, $wire, $config->{messages}); 1 }
            or exit 3;
        close $sender;
        exit 0;
    }

    close $sender;
    close $gate_read;
    my $loop = Linux::Event::Loop->new;
    my $state = {
        loop => $loop,
        payload => $payload,
        messages => 0,
        expected_messages => $config->{messages},
    };
    my $callback = $case->{callback}->();
    my %callback_option = defined($callback)
        ? (on_message => $callback) : ();
    my @streams;
    my @idle_peers;
    my $rss_before_setup = current_rss_kib();
    my $setup_start = clock_gettime(CLOCK_MONOTONIC);
    push @streams, Linux::Event::Bench::CachedClosureStream->new(
        loop => $loop,
        fh => $receiver,
        data => $state,
        %callback_option,
    );
    for (1 .. $config->{idle_connections}) {
        socketpair(my $idle_stream, my $idle_peer,
            AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
        push @idle_peers, $idle_peer;
        push @streams, Linux::Event::Bench::CachedClosureStream->new(
            loop => $loop,
            fh => $idle_stream,
            data => $state,
            %callback_option,
        );
    }
    my $setup_end = clock_gettime(CLOCK_MONOTONIC);
    my $rss_after_setup = current_rss_kib();

    my $wall_start = clock_gettime(CLOCK_MONOTONIC);
    my $cpu_start = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
    syswrite($gate_write, 'g') == 1 or die "release writer: $!";
    close $gate_write;

    local $SIG{ALRM} = sub { die "first-class framed callback benchmark timed out\n" };
    alarm 120;
    my $ok = eval { $loop->run; 1 };
    my $error = $@;
    alarm 0;
    my $cpu_end = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
    my $wall_end = clock_gettime(CLOCK_MONOTONIC);

    if (!$ok) {
        kill 'TERM', $writer;
        waitpid($writer, 0);
        die $error;
    }
    waitpid($writer, 0);
    die "writer failed with status $?\n" if $? != 0;

    my $active = $streams[0];
    my $stats = $active->{xs_state}->stats;
    die "received $state->{messages}, expected $config->{messages}\n"
        if $state->{messages} != $config->{messages};
    die "native parser emitted $stats->{frames_emitted}, expected $config->{messages}\n"
        if $stats->{frames_emitted} != $config->{messages};
    die "native callback count is $stats->{message_callback_calls}, expected $config->{messages}\n"
        if $stats->{message_callback_calls} != $config->{messages};

    my $elapsed = $wall_end - $wall_start;
    my $cpu = $cpu_end - $cpu_start;
    my $stream_count = 1 + $config->{idle_connections};
    for my $stream (@streams) {
        $stream->close if !$stream->is_closed;
    }
    for my $peer (@idle_peers) {
        close $peer;
    }

    return {
        case => $case->{name},
        payload_size => $config->{payload_size},
        idle_connections => $config->{idle_connections},
        messages => $config->{messages},
        elapsed_seconds => 0 + $elapsed,
        receiver_cpu_seconds => 0 + $cpu,
        messages_per_second => $config->{messages} / $elapsed,
        cpu_us_per_message => $cpu * 1_000_000 / $config->{messages},
        setup_us_per_stream => ($setup_end - $setup_start) * 1_000_000
            / $stream_count,
        rss_before_setup_kib => $rss_before_setup,
        rss_after_setup_kib => $rss_after_setup,
        rss_setup_delta_kib => $rss_after_setup - $rss_before_setup,
        read_calls => $stats->{read_calls},
        frames_emitted => $stats->{frames_emitted},
        callback_calls => $stats->{message_callback_calls},
    };
}

sub write_frames ($fh, $wire, $messages) {
    my $frames_per_chunk = int(65_536 / length($wire));
    $frames_per_chunk = 1 if $frames_per_chunk < 1;
    my $remaining = $messages;
    while ($remaining) {
        my $count = $remaining < $frames_per_chunk
            ? $remaining : $frames_per_chunk;
        write_all($fh, $wire x $count);
        $remaining -= $count;
    }
    return;
}

sub write_all ($fh, $bytes) {
    my $offset = 0;
    while ($offset < length($bytes)) {
        my $written = syswrite($fh, $bytes, length($bytes) - $offset, $offset);
        next if !defined($written) && $!{EINTR};
        die "writer syswrite: $!\n" if !defined $written;
        die "writer syswrite returned zero\n" if $written == 0;
        $offset += $written;
    }
    return;
}

sub current_rss_kib () {
    open my $status, '<', '/proc/self/status' or return 0;
    while (my $line = <$status>) {
        if ($line =~ /\AVmRSS:\s+(\d+)\s+kB\s*\z/) {
            close $status;
            return 0 + $1;
        }
    }
    close $status;
    return 0;
}

sub rotate_cases ($cases, $offset) {
    my $count = @$cases;
    $offset %= $count;
    return (@$cases[$offset .. $count - 1], @$cases[0 .. $offset - 1]);
}

sub median (@values) {
    @values = sort { $a <=> $b } @values;
    return $values[int(@values / 2)] if @values % 2;
    return ($values[@values / 2 - 1] + $values[@values / 2]) / 2;
}

sub usage ($status) {
    print <<'USAGE';
Usage:
  perl -Iblib/lib -Iblib/arch bench/run-first-class-framed-callback-bench.pl [options]

Options:
  --payload-sizes=16,4096,65536
  --idle-connections=0,63
  --target-mib=16
  --minimum-messages=512
  --repeats=7
  --warmup=1
  --json=path

The benchmark compares one cached subclass method CV with a cached constructor
coderef, a closure retaining one lexical, and a closure retaining four
lexicals. Every case uses the same native delimiter framer and the same
executed callback work. Cases rotate within each repeated configuration.
Receiver process CPU excludes the forked blocking writer.
USAGE
    exit $status;
}
