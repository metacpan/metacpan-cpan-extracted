#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Config;
use Getopt::Long qw(GetOptions);
use JSON::PP qw(encode_json);
use POSIX qw(_exit);
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SO_RCVBUF SO_SNDBUF);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);

use Linux::Event::Loop;
use Linux::Event::Async;

our $READ_SIZE = 262_144;

{
    package LE::Bench::AsyncConsumerLifetime;
    use parent 'Linux::Event::Async::Stream';
    use Linux::Event::Framer 'Delimiter', "\n";

    sub stream_tuning ($class) {
        return read_size => $main::READ_SIZE,
            read_budget_bytes => $main::READ_SIZE;
    }
}

my @command_argv = @ARGV;
my $sizes = '64,256,1024,4096,16384,32768,65536,131072,200000';
my $repeat = 3;
my $warmup = 1;
my $variant = 'unspecified';
my $core_commit = 'unknown';
my $async_commit = 'unknown';
my $output;

GetOptions(
    'sizes=s' => \$sizes,
    'repeat=i' => \$repeat,
    'warmup=i' => \$warmup,
    'variant=s' => \$variant,
    'core-commit=s' => \$core_commit,
    'async-commit=s' => \$async_commit,
    'output=s' => \$output,
) or die "invalid options\n";

die "--output is required\n" if !defined($output) || $output eq '';
die "repeat must be positive\n" if $repeat < 1;
die "warmup must be non-negative\n" if $warmup < 0;
my @sizes = map { 0 + $_ } split /,/, $sizes;
die "sizes must contain positive integers\n"
    if !@sizes || grep { $_ < 1 } @sizes;

sub messages_for_size ($size) {
    return 2_000_000 if $size <= 256;
    return 1_000_000 if $size <= 1_024;
    return 500_000 if $size <= 4_096;
    return 300_000 if $size <= 16_384;
    return 150_000 if $size <= 32_768;
    return 50_000 if $size <= 65_536;
    return 25_000 if $size <= 131_072;
    return 30_000;
}

sub median (@values) {
    @values = sort { $a <=> $b } @values;
    return $values[int(@values / 2)];
}

sub percentile ($fraction, @values) {
    @values = sort { $a <=> $b } @values;
    my $index = int($fraction * $#values + 0.5);
    return $values[$index];
}

sub write_all ($fh, $bytes, $calls) {
    my $offset = 0;
    my $length = length $bytes;
    while ($offset < $length) {
        my $written = syswrite($fh, $bytes, $length - $offset, $offset);
        die "producer write: $!" if !defined $written;
        $$calls++;
        $offset += $written;
    }
}

sub run_once ($payload_size, $messages) {
    socketpair(my $receiver_fh, my $producer_fh,
        AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
    pipe(my $barrier_r, my $barrier_w) or die "barrier pipe: $!";
    pipe(my $metrics_r, my $metrics_w) or die "metrics pipe: $!";

    my $receive_buffer = unpack('i', getsockopt(
        $receiver_fh, SOL_SOCKET, SO_RCVBUF) // pack('i', 0));
    my $send_buffer = unpack('i', getsockopt(
        $producer_fh, SOL_SOCKET, SO_SNDBUF) // pack('i', 0));

    my $pid = fork();
    die "fork: $!" if !defined $pid;
    if ($pid == 0) {
        close $receiver_fh;
        close $barrier_w;
        close $metrics_r;
        my $go = '';
        sysread($barrier_r, $go, 1) == 1 or _exit(2);
        close $barrier_r;

        my $frame = ('x' x $payload_size) . "\n";
        my $batch_frames = $payload_size <= 256 ? 64
            : $payload_size <= 4_096 ? 16
            : $payload_size <= 32_768 ? 4 : 1;
        my $batch = $frame x $batch_frames;
        my $remaining = $messages;
        my $write_calls = 0;
        eval {
            while ($remaining >= $batch_frames) {
                write_all($producer_fh, $batch, \$write_calls);
                $remaining -= $batch_frames;
            }
            write_all($producer_fh, $frame x $remaining, \$write_calls)
                if $remaining;
            1;
        } or _exit(3);
        syswrite($metrics_w, "$write_calls\n");
        close $metrics_w;
        close $producer_fh;
        _exit(0);
    }

    close $producer_fh;
    close $barrier_r;
    close $metrics_w;

    my $loop = Linux::Event::Loop->new;
    my $stream = LE::Bench::AsyncConsumerLifetime->new(
        loop => $loop, fh => $receiver_fh,
    );
    my $count = 0;
    my $ready;
    $ready = sub {
        my $message = Linux::Event::Async::Stream::_recv_get($stream);
        die "unexpected EOF after $count messages" if !defined $message;
        $count++;
        if ($count == $messages) {
            $loop->stop;
            return;
        }
        Linux::Event::Async::Stream::_recv_arm($stream);
        Linux::Event::Async::Stream::_recv_on_ready($stream, $ready);
    };
    Linux::Event::Async::Stream::_recv_arm($stream);
    Linux::Event::Async::Stream::_recv_on_ready($stream, $ready);

    my @cpu_before = times;
    my $started = clock_gettime(CLOCK_MONOTONIC);
    syswrite($barrier_w, 'G') == 1 or die "barrier release: $!";
    close $barrier_w;
    $loop->run;
    my $elapsed = clock_gettime(CLOCK_MONOTONIC) - $started;
    my @cpu_after = times;
    my $cpu_seconds = ($cpu_after[0] - $cpu_before[0])
        + ($cpu_after[1] - $cpu_before[1]);

    waitpid($pid, 0);
    die "producer failed with status $?" if $? != 0;
    my $metric_line = <$metrics_r> // '';
    close $metrics_r;
    my $write_calls = $metric_line =~ /^(\d+)/ ? 0 + $1 : undef;
    die "delivered $count of $messages messages" if $count != $messages;

    my $stats = $stream->{xs_state}->stats;
    my $options = $stream->{descriptor}{options};
    my $bytes = $messages * $payload_size;
    my $sample = {
        wall_seconds => 0 + sprintf('%.9f', $elapsed),
        cpu_seconds => 0 + sprintf('%.9f', $cpu_seconds),
        messages_per_second => 0 + sprintf('%.3f', $messages / $elapsed),
        mebibytes_per_second => 0 + sprintf('%.3f',
            $bytes / $elapsed / 1_048_576),
        cpu_nanoseconds_per_byte => $cpu_seconds > 0
            ? 0 + sprintf('%.6f', $cpu_seconds * 1_000_000_000 / $bytes)
            : undef,
        read_calls => 0 + $stats->{read_calls},
        reads_per_message => 0 + sprintf('%.9f',
            $stats->{read_calls} / $messages),
        producer_write_calls => $write_calls,
        writes_per_message => defined($write_calls)
            ? 0 + sprintf('%.9f', $write_calls / $messages) : undef,
        consumer_message_calls => 0 + $stats->{consumer_message_calls},
        consumer_flush_calls => 0 + $stats->{consumer_flush_calls},
        perl_ready_callbacks => $messages,
        callbacks_per_message => 1,
        input_peak_bytes => 0 + $stats->{input_peak_bytes},
    };
    my $effective = {
        delivery_mode => 'framed_native_consumer',
        framer => {
            family => 'Delimiter',
            delimiter_hex => '0a',
            include_delimiter => JSON::PP::false,
            max_frame => undef,
        },
        transport => 'AF_UNIX_SOCK_STREAM_socketpair',
        tls => { enabled => JSON::PP::false },
        edge_triggered => JSON::PP::false,
        concurrency => 1,
        topology => 'forked producer, parent receiver, start barrier',
        read_size => 0 + $options->{read_size},
        read_budget_bytes => 0 + $options->{read_budget_bytes},
        read_batch_bytes => 0 + $options->{read_batch_bytes},
        message_batch_size => 0 + $options->{message_batch_size},
        max_buffer => 0 + $options->{max_buffer},
        high_watermark => 0 + $options->{high_watermark},
        low_watermark => 0 + $options->{low_watermark},
        max_pending_bytes => 0 + $options->{max_pending_bytes},
        receiver_socket_buffer => $receive_buffer,
        producer_socket_buffer => $send_buffer,
        socket_options => 'OS defaults; TCP_NODELAY not applicable',
        async_prefetch_max_messages => 64,
        async_prefetch_max_bytes => 262_144,
        latency => 'not sampled; throughput-focused local transport benchmark',
        cpu_affinity => 'not set',
    };
    $stream->close;
    return ($sample, $effective);
}

my @results;
my $effective_config;
for my $payload_size (@sizes) {
    my $messages = messages_for_size($payload_size);
    run_once($payload_size, $messages) for 1 .. $warmup;
    my @samples;
    for (1 .. $repeat) {
        my ($sample, $effective) = run_once($payload_size, $messages);
        push @samples, $sample;
        $effective_config //= $effective;
    }
    my @rates = map { $_->{messages_per_second} } @samples;
    my @throughput = map { $_->{mebibytes_per_second} } @samples;
    push @results, {
        payload_bytes => $payload_size,
        wire_bytes_per_message => $payload_size + 1,
        messages => $messages,
        samples => \@samples,
        summary => {
            median_messages_per_second => median(@rates),
            p50_messages_per_second => percentile(0.50, @rates),
            p99_messages_per_second => percentile(0.99, @rates),
            median_mebibytes_per_second => median(@throughput),
        },
    };
}

my $record = {
    schema_version => 1,
    benchmark => 'async_consumer_host_lifetime',
    variant => $variant,
    core_commit => $core_commit,
    async_commit => $async_commit,
    generated_at_epoch => time,
    command => join(' ', $^X, $0, @command_argv),
    runtime => {
        perl => "$^V",
        os => $^O,
        archname => $Config{archname},
        compiler => $Config{cc},
        compiler_flags => $Config{ccflags},
        optimize => $Config{optimize},
    },
    effective_config => $effective_config,
    repetitions => $repeat,
    warmups => $warmup,
    results => \@results,
};

open my $fh, '>', $output or die "open $output: $!";
print {$fh} JSON::PP->new->canonical->pretty->encode($record);
close $fh or die "close $output: $!";
say $output;
