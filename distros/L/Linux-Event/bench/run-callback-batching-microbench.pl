#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use IO::Socket::INET;
use JSON::PP;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC CLOCK_PROCESS_CPUTIME_ID);

use Linux::Event;
use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;

my $messages = 200_000;
my $bytes = 64;
my $read_size = 4_096;
my @raw_batch_bytes = (0, 16_384, 65_536, 262_144);
my @message_batch_sizes = (0, 1, 4, 16, 64, 256);
my @transports = qw(unix tcp);
my $warmup = 1;
my $repeats = 5;
my $json_path;
my $help;

GetOptions(
    'messages=i'            => \$messages,
    'bytes=i'               => \$bytes,
    'read-size=i'           => \$read_size,
    'raw-batch-bytes=s'     => sub {
        @raw_batch_bytes = map { 0 + $_ } split /,/, $_[1];
    },
    'message-batch-sizes=s' => sub {
        @message_batch_sizes = map { 0 + $_ } split /,/, $_[1];
    },
    'transports=s'          => sub { @transports = split /,/, $_[1] },
    'warmup=i'              => \$warmup,
    'repeats=i'             => \$repeats,
    'json=s'                => \$json_path,
    'help'                  => \$help,
) or usage(1);
usage(0) if $help;

die "messages must be positive\n" if $messages < 1;
die "bytes must be positive\n" if $bytes < 1;
die "read-size must be positive\n" if $read_size < 1;
die "warmup must be non-negative\n" if $warmup < 0;
die "repeats must be positive\n" if $repeats < 1;
die "raw batch byte limits must be non-negative\n"
    if grep { $_ < 0 } @raw_batch_bytes;
die "message batch sizes must be non-negative\n"
    if grep { $_ < 0 } @message_batch_sizes;
my %valid_transport = map { $_ => 1 } qw(unix tcp);
die "unknown transport\n" if grep { !$valid_transport{$_} } @transports;

my @cases;
for my $transport (@transports) {
    push @cases, map {
        +{ mode => 'raw', transport => $transport, batch => $_ }
    } @raw_batch_bytes;
    push @cases, map {
        +{ mode => 'framed', transport => $transport, batch => $_ }
    } @message_batch_sizes;
}

for my $case (@cases) {
    run_case($case) for 1 .. $warmup;
}

my @raw;
for my $repeat (1 .. $repeats) {
    my @ordered = rotate_cases(\@cases, $repeat - 1);
    for my $case (@ordered) {
        my $row = run_case($case);
        $row->{repeat} = $repeat;
        push @raw, $row;
        printf "%s/%s batch=%d repeat=%d %.1f MiB/s %.3f cpu us/MiB callbacks=%d\n",
            $case->{transport}, $case->{mode}, $case->{batch}, $repeat,
            $row->{payload_mib_per_second}, $row->{cpu_us_per_mib},
            $row->{callback_calls};
    }
}

my @summary;
for my $case (@cases) {
    my @rows = grep {
        $_->{transport} eq $case->{transport}
            && $_->{mode} eq $case->{mode}
            && $_->{batch} == $case->{batch}
    } @raw;
    push @summary, {
        %$case,
        median_payload_mib_per_second => median(
            map { $_->{payload_mib_per_second} } @rows,
        ),
        median_messages_per_second => median(
            map { $_->{messages_per_second} } @rows,
        ),
        median_cpu_us_per_mib => median(map { $_->{cpu_us_per_mib} } @rows),
        median_callback_calls => median(map { $_->{callback_calls} } @rows),
        median_read_calls => median(map { $_->{read_calls} } @rows),
        median_peak_batch => median(map { $_->{peak_batch} } @rows),
    };
}

for my $row (@summary) {
    my ($base) = grep {
        $_->{transport} eq $row->{transport}
            && $_->{mode} eq $row->{mode}
            && $_->{batch} == 0
    } @summary;
    next if !$base;
    $row->{throughput_change_percent} = $base->{median_payload_mib_per_second}
        ? 100 * ($row->{median_payload_mib_per_second}
            / $base->{median_payload_mib_per_second} - 1)
        : 0;
    $row->{callback_reduction_percent} = $base->{median_callback_calls}
        ? 100 * (1 - $row->{median_callback_calls}
            / $base->{median_callback_calls})
        : 0;
}

say "\nCallback batching microbenchmark";
printf "messages=%d payload=%d read_size=%d warmup=%d repeats=%d\n",
    $messages, $bytes, $read_size, $warmup, $repeats;
printf "%-6s %-7s %10s %12s %11s %11s %12s %10s\n",
    'xport', 'mode', 'batch', 'MiB/s', 'change', 'callbacks',
    'cb reduction', 'peak';
for my $row (@summary) {
    printf "%-6s %-7s %10d %12.1f %+10.1f%% %11.0f %11.1f%% %10.0f\n",
        $row->{transport}, $row->{mode}, $row->{batch},
        $row->{median_payload_mib_per_second},
        $row->{throughput_change_percent} // 0,
        $row->{median_callback_calls},
        $row->{callback_reduction_percent} // 0,
        $row->{median_peak_batch};
}

if (defined $json_path) {
    my $report = {
        benchmark => 'linux-event-callback-batching-microbench',
        benchmark_contract_version => 1,
        linux_event_version => $Linux::Event::VERSION,
        configuration => {
            messages => $messages,
            bytes => $bytes,
            read_size => $read_size,
            raw_batch_bytes => \@raw_batch_bytes,
            message_batch_sizes => \@message_batch_sizes,
            transports => \@transports,
            warmup => $warmup,
            repeats => $repeats,
        },
        raw => \@raw,
        summary => \@summary,
    };
    open my $json, '>', $json_path or die "open $json_path: $!\n";
    print {$json} JSON::PP->new->canonical->pretty->encode($report);
    close $json or die "close $json_path: $!\n";
}

sub run_case ($case) {
    my ($receiver, $sender) = connected_pair($case->{transport});
    pipe(my $gate_read, my $gate_write) or die "gate pipe: $!";

    my $payload = 'x' x $bytes;
    my $wire = $case->{mode} eq 'framed' ? $payload . "\n" : $payload;
    my $writer = fork();
    die "writer fork: $!" if !defined $writer;
    if ($writer == 0) {
        close $receiver;
        close $gate_write;
        my $gate = '';
        sysread($gate_read, $gate, 1) == 1 or exit 2;
        close $gate_read;
        eval { write_messages($sender, $wire, $messages); 1 } or exit 3;
        close $sender;
        exit 0;
    }

    close $sender;
    close $gate_read;
    my $loop = Linux::Event::Loop->new;
    my $state = {
        loop => $loop,
        mode => $case->{mode},
        messages => 0,
        bytes => 0,
        expected_messages => $messages,
        expected_bytes => $messages * $bytes,
    };
    my $class = benchmark_class($case->{mode}, $case->{batch});
    my $stream = $class->new(loop => $loop, fh => $receiver, data => $state);

    my $wall_start = clock_gettime(CLOCK_MONOTONIC);
    my $cpu_start = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
    syswrite($gate_write, 'g') == 1 or die "release writer: $!";
    close $gate_write;

    local $SIG{ALRM} = sub { die "batching benchmark timed out\n" };
    alarm 60;
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

    my $stats = $stream->{xs_state}->stats;
    my $got = $case->{mode} eq 'framed' ? $state->{messages} : $state->{bytes};
    my $expected = $case->{mode} eq 'framed'
        ? $state->{expected_messages} : $state->{expected_bytes};
    die "received $got, expected $expected\n" if $got != $expected;

    my $elapsed = $wall_end - $wall_start;
    my $cpu = $cpu_end - $cpu_start;
    my $payload_bytes = $messages * $bytes;
    my $payload_mib = $payload_bytes / 1_048_576;
    my $callback_calls = $case->{mode} eq 'framed'
        ? $stats->{message_callback_calls} + $stats->{message_batch_calls}
        : $stats->{delivery_calls};
    my $peak_batch = $case->{mode} eq 'framed'
        ? ($stats->{message_batch_peak_messages} || 1)
        : ($stats->{read_batch_peak_bytes} || $read_size);

    $stream->close if !$stream->is_closed;
    return {
        %$case,
        elapsed_seconds => 0 + $elapsed,
        receiver_cpu_seconds => 0 + $cpu,
        payload_bytes => $payload_bytes,
        payload_mib_per_second => $payload_mib / $elapsed,
        messages_per_second => $messages / $elapsed,
        cpu_us_per_mib => $cpu * 1_000_000 / $payload_mib,
        callback_calls => $callback_calls,
        read_calls => $stats->{read_calls},
        peak_batch => $peak_batch,
        frames_emitted => $stats->{frames_emitted},
        read_batch_flushes => $stats->{read_batch_flushes},
        message_batch_calls => $stats->{message_batch_calls},
    };
}

my %benchmark_class;
sub benchmark_class ($mode, $batch) {
    my $key = "$mode:$batch:$read_size";
    return $benchmark_class{$key} if $benchmark_class{$key};
    my $suffix = join '_', $mode, $batch, $read_size;
    my $class = "Linux::Event::Bench::CallbackBatch::$suffix";

    if ($mode eq 'framed') {
        eval qq{
            package $class;
            use parent 'Linux::Event::IO::Sock::Stream';
            use Linux::Event::Framer 'Delimiter', "\\n";
            1;
        } or die "define framed benchmark class: $@";
    } else {
        no strict 'refs';
        @{"${class}::ISA"} = ('Linux::Event::IO::Sock::Stream');
    }

    no strict 'refs';
    *{"${class}::stream_tuning"} = $mode eq 'raw'
        ? sub ($class_name) {
            return read_size => $read_size, read_batch_bytes => $batch;
        }
        : sub ($class_name) {
            return read_size => $read_size, message_batch_size => $batch;
        };
    if ($mode eq 'raw') {
        *{"${class}::on_data"} = sub ($stream, $chunk) {
            $stream->data->{bytes} += length($chunk);
        };
    } elsif ($batch) {
        *{"${class}::on_messages"} = sub ($stream, $batch_messages) {
            $stream->data->{messages} += scalar @$batch_messages;
        };
    } else {
        *{"${class}::on_message"} = sub ($stream, $message) {
            $stream->data->{messages}++;
        };
    }
    *{"${class}::on_eof"} = sub ($stream) { $stream->data->{loop}->stop };
    *{"${class}::on_error"} = sub ($stream, $error) {
        die "benchmark Stream error: $error\n";
    };
    $benchmark_class{$key} = $class;
    return $class;
}

sub connected_pair ($transport) {
    if ($transport eq 'unix') {
        socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
            or die "socketpair: $!";
        return ($left, $right);
    }

    my $listener = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0,
        Proto => 'tcp', Listen => 1, ReuseAddr => 1,
    ) or die "TCP listener: $!";
    my $sender = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $listener->sockport,
        Proto => 'tcp',
    ) or die "TCP connect: $!";
    my $receiver = $listener->accept or die "TCP accept: $!";
    close $listener;
    return ($receiver, $sender);
}

sub write_messages ($fh, $wire, $count) {
    my $per_chunk = int(65_536 / length($wire));
    $per_chunk = 1 if $per_chunk < 1;
    my $chunk = $wire x $per_chunk;
    while ($count > 0) {
        my $take = $count < $per_chunk ? $count : $per_chunk;
        my $bytes = $take == $per_chunk ? $chunk : $wire x $take;
        write_all($fh, $bytes);
        $count -= $take;
    }
}

sub write_all ($fh, $bytes) {
    my $offset = 0;
    my $length = length($bytes);
    while ($offset < $length) {
        my $written = syswrite($fh, $bytes, $length - $offset, $offset);
        if (defined $written) {
            $offset += $written;
            next;
        }
        next if $!{EINTR};
        die "writer syswrite: $!";
    }
}

sub rotate_cases ($cases, $offset) {
    return @$cases if !@$cases;
    $offset %= @$cases;
    return (@$cases[$offset .. $#$cases], @$cases[0 .. $offset - 1]);
}

sub median (@values) {
    @values = sort { $a <=> $b } @values;
    my $middle = int(@values / 2);
    return @values % 2
        ? $values[$middle]
        : ($values[$middle - 1] + $values[$middle]) / 2;
}

sub usage ($exit) {
    print <<'USAGE';
Usage: run-callback-batching-microbench.pl [options]
  --messages=N                 logical payloads per case (default: 200000)
  --bytes=N                    payload bytes (default: 64)
  --read-size=N                native syscall read size (default: 4096)
  --raw-batch-bytes=LIST       zero or byte limits (default: 0,16384,65536,262144)
  --message-batch-sizes=LIST   zero or frame limits (default: 0,1,4,16,64,256)
  --transports=LIST            unix,tcp (default: unix,tcp)
  --warmup=N                   untimed case sweeps (default: 1)
  --repeats=N                  measured sweeps (default: 5)
  --json=PATH                  write machine-readable report
  --help                       show this help

Zero selects the ordinary callback path. Raw rows report byte aggregation;
framed rows use newline-delimited pipelined messages and explicit array batches.
USAGE
    exit $exit;
}
