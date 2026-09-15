#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Config;
use File::Basename qw(dirname);
use File::Path qw(make_path);
use Getopt::Long qw(GetOptions);
use JSON::PP qw(encode_json decode_json);
use POSIX qw(_exit uname);
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SO_RCVBUF SO_SNDBUF);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC CLOCK_PROCESS_CPUTIME_ID);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;

our $READ_SIZE = 262_144;

{
    package Linux::Event::Bench::PayloadSweep::Base;
    use parent 'Linux::Event::IO::Sock::Stream';

    sub stream_tuning ($class) {
        return read_size => $main::READ_SIZE,
            read_budget_bytes => $main::READ_SIZE;
    }

    sub on_error ($stream, $error) { die "Stream error: $error\n" }
    sub on_eof ($stream) {
        my $state = $stream->data;
        die "producer EOF after $state->{received_bytes} of "
            . "$state->{target_bytes} payload bytes\n"
            if $state->{received_bytes} != $state->{target_bytes};
    }
}

{
    package Linux::Event::Bench::PayloadSweep::Raw;
    use parent -norequire, 'Linux::Event::Bench::PayloadSweep::Base';
    sub on_data ($stream, $bytes) { main::receive_raw($stream, $bytes) }
}

{
    package Linux::Event::Bench::PayloadSweep::Delimiter;
    use parent -norequire, 'Linux::Event::Bench::PayloadSweep::Base';
    use Linux::Event::Framer 'Delimiter', "\n";
    sub on_message ($stream, $message) {
        main::receive_message($stream, $message);
    }
}

my @command_argv = @ARGV;
my $sizes = '64,256,1024,4096,16384,32768,65536,131072,200000';
my $modes = 'raw,delimiter';
my $repeats = 5;
my $warmup = 1;
my $target_bytes = 256 * 1024 * 1024;
my $min_messages = 2_000;
my $max_messages = 1_000_000;
my $variant = 'unspecified';
my $commit = 'unknown';
my $output;

GetOptions(
    'sizes=s' => \$sizes,
    'modes=s' => \$modes,
    'repeats=i' => \$repeats,
    'warmup=i' => \$warmup,
    'target-bytes=i' => \$target_bytes,
    'min-messages=i' => \$min_messages,
    'max-messages=i' => \$max_messages,
    'read-size=i' => \$READ_SIZE,
    'variant=s' => \$variant,
    'commit=s' => \$commit,
    'output=s' => \$output,
) or die "invalid options\n";

die "--output is required\n" if !defined($output) || $output eq '';
die "repeats must be positive\n" if $repeats < 1;
die "warmup must be non-negative\n" if $warmup < 0;
die "target-bytes, min-messages, max-messages, and read-size must be positive\n"
    if grep { $_ < 1 } ($target_bytes, $min_messages, $max_messages, $READ_SIZE);
die "min-messages must not exceed max-messages\n"
    if $min_messages > $max_messages;

my @sizes = map { 0 + $_ } split /,/, $sizes;
die "sizes must contain positive integers\n"
    if !@sizes || grep { $_ < 1 } @sizes;
my @modes = split /,/, $modes;
my %known_mode = map { $_ => 1 } qw(raw delimiter);
die "modes must contain raw and/or delimiter\n"
    if !@modes || grep { !$known_mode{$_} } @modes;

sub messages_for_size ($size) {
    my $messages = int($target_bytes / $size);
    $messages = $min_messages if $messages < $min_messages;
    $messages = $max_messages if $messages > $max_messages;
    return $messages;
}

sub median (@values) {
    @values = sort { $a <=> $b } @values;
    return $values[int(@values / 2)];
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

sub receive_raw ($stream, $bytes) {
    my $state = $stream->data;
    $state->{received_bytes} += length $bytes;
    $state->{perl_callbacks}++;
    die "raw receiver exceeded expected payload bytes\n"
        if $state->{received_bytes} > $state->{target_bytes};
    $state->{loop}->stop
        if $state->{received_bytes} == $state->{target_bytes};
}

sub receive_message ($stream, $message) {
    my $state = $stream->data;
    die "framed payload mismatch\n"
        if length($message) != $state->{payload_size}
            || $message ne $state->{payload};
    $state->{received_messages}++;
    $state->{received_bytes} += length $message;
    $state->{perl_callbacks}++;
    $state->{loop}->stop
        if $state->{received_messages} == $state->{messages};
}

sub run_once ($mode, $payload_size, $messages) {
    socketpair(my $receiver_fh, my $producer_fh,
        AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
    pipe(my $barrier_r, my $barrier_w) or die "barrier pipe: $!";
    pipe(my $metrics_r, my $metrics_w) or die "metrics pipe: $!";

    my $receiver_socket_buffer = unpack('i', getsockopt(
        $receiver_fh, SOL_SOCKET, SO_RCVBUF) // pack('i', 0));
    my $producer_socket_buffer = unpack('i', getsockopt(
        $producer_fh, SOL_SOCKET, SO_SNDBUF) // pack('i', 0));
    my $payload = 'x' x $payload_size;
    my $wire = $mode eq 'delimiter' ? "$payload\n" : $payload;

    my $pid = fork();
    die "fork: $!" if !defined $pid;
    if ($pid == 0) {
        close $receiver_fh;
        close $barrier_w;
        close $metrics_r;
        my $go = '';
        sysread($barrier_r, $go, 1) == 1 or _exit(2);
        close $barrier_r;

        my $batch_messages = int(262_144 / length($wire));
        $batch_messages = 1 if $batch_messages < 1;
        $batch_messages = 64 if $batch_messages > 64;
        my $batch = $wire x $batch_messages;
        my $remaining = $messages;
        my $write_calls = 0;
        my $cpu_start = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
        my $ok = eval {
            while ($remaining >= $batch_messages) {
                write_all($producer_fh, $batch, \$write_calls);
                $remaining -= $batch_messages;
            }
            write_all($producer_fh, $wire x $remaining, \$write_calls)
                if $remaining;
            1;
        };
        my $producer_cpu = clock_gettime(CLOCK_PROCESS_CPUTIME_ID) - $cpu_start;
        _exit(3) if !$ok;
        my $metrics = encode_json({
            write_calls => $write_calls,
            cpu_seconds => 0 + sprintf('%.9f', $producer_cpu),
            batch_messages => $batch_messages,
        });
        syswrite($metrics_w, $metrics) == length($metrics) or _exit(4);
        close $metrics_w;
        close $producer_fh;
        _exit(0);
    }

    close $producer_fh;
    close $barrier_r;
    close $metrics_w;

    my $loop = Linux::Event::Loop->new;
    my $state = {
        loop => $loop,
        messages => $messages,
        payload => $payload,
        payload_size => $payload_size,
        target_bytes => $messages * $payload_size,
        received_messages => 0,
        received_bytes => 0,
        perl_callbacks => 0,
    };
    my $class = $mode eq 'raw'
        ? 'Linux::Event::Bench::PayloadSweep::Raw'
        : 'Linux::Event::Bench::PayloadSweep::Delimiter';
    my $stream = $class->new(
        loop => $loop,
        fh => $receiver_fh,
        data => $state,
    );

    my $cpu_start = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
    my $wall_start = clock_gettime(CLOCK_MONOTONIC);
    syswrite($barrier_w, 'G') == 1 or die "barrier release: $!";
    close $barrier_w;
    $loop->run;
    my $wall_seconds = clock_gettime(CLOCK_MONOTONIC) - $wall_start;
    my $receiver_cpu = clock_gettime(CLOCK_PROCESS_CPUTIME_ID) - $cpu_start;

    waitpid($pid, 0);
    die "producer failed with status $?\n" if $? != 0;
    my $metric_text = do { local $/; <$metrics_r> // '' };
    close $metrics_r;
    my $producer_metrics = decode_json($metric_text);
    die "received $state->{received_bytes} of $state->{target_bytes} bytes\n"
        if $state->{received_bytes} != $state->{target_bytes};
    die "received $state->{received_messages} of $messages messages\n"
        if $mode eq 'delimiter' && $state->{received_messages} != $messages;

    my $stats = $stream->{xs_state}->stats;
    my $options = $stream->{descriptor}{options};
    my $bytes = $state->{target_bytes};
    my $sample = {
        mode => $mode,
        payload_bytes => $payload_size,
        wire_bytes_per_message => length($wire),
        messages => $messages,
        wall_seconds => 0 + sprintf('%.9f', $wall_seconds),
        receiver_cpu_seconds => 0 + sprintf('%.9f', $receiver_cpu),
        producer_cpu_seconds => $producer_metrics->{cpu_seconds},
        messages_per_second => 0 + sprintf('%.3f', $messages / $wall_seconds),
        mebibytes_per_second => 0 + sprintf('%.3f',
            $bytes / $wall_seconds / 1_048_576),
        receiver_cpu_nanoseconds_per_byte => 0 + sprintf('%.6f',
            $receiver_cpu * 1_000_000_000 / $bytes),
        producer_cpu_nanoseconds_per_byte => 0 + sprintf('%.6f',
            $producer_metrics->{cpu_seconds} * 1_000_000_000 / $bytes),
        read_calls => 0 + $stats->{read_calls},
        reads_per_message => 0 + sprintf('%.9f',
            $stats->{read_calls} / $messages),
        producer_write_calls => 0 + $producer_metrics->{write_calls},
        writes_per_message => 0 + sprintf('%.9f',
            $producer_metrics->{write_calls} / $messages),
        perl_callbacks => 0 + $state->{perl_callbacks},
        callbacks_per_message => 0 + sprintf('%.9f',
            $state->{perl_callbacks} / $messages),
        input_peak_bytes => 0 + $stats->{input_peak_bytes},
        input_compactions => 0 + $stats->{input_compactions},
    };
    my $effective = {
        delivery_mode => $mode eq 'raw' ? 'on_data' : 'on_message',
        framer => $mode eq 'raw' ? undef : {
            family => 'Delimiter',
            delimiter_hex => '0a',
            include_delimiter => JSON::PP::false,
            max_frame => undef,
        },
        transport => 'AF_UNIX SOCK_STREAM socketpair',
        topology => 'forked blocking producer; parent Loop/Stream receiver; start barrier',
        concurrency => 1,
        tls => { enabled => JSON::PP::false },
        edge_triggered => JSON::PP::false,
        read_size => 0 + $options->{read_size},
        read_budget_bytes => 0 + $options->{read_budget_bytes},
        read_batch_bytes => 0 + $options->{read_batch_bytes},
        message_batch_size => 0 + $options->{message_batch_size},
        max_buffer => 0 + $options->{max_buffer},
        high_watermark => 0 + $options->{high_watermark},
        low_watermark => 0 + $options->{low_watermark},
        max_pending_bytes => 0 + $options->{max_pending_bytes},
        producer_batch_messages => 0 + $producer_metrics->{batch_messages},
        receiver_socket_buffer => $receiver_socket_buffer,
        producer_socket_buffer => $producer_socket_buffer,
        socket_options => 'OS defaults; TCP_NODELAY not applicable',
        latency => 'not sampled; saturated one-way throughput baseline',
        cpu_affinity => 'not set',
    };
    $stream->close;
    return ($sample, $effective);
}

my @samples;
my %effective_config_by_mode;
for my $mode (@modes) {
    for my $payload_size (@sizes) {
        my $messages = messages_for_size($payload_size);
        run_once($mode, $payload_size, $messages) for 1 .. $warmup;
        for my $repeat (1 .. $repeats) {
            my ($sample, $effective) = run_once(
                $mode, $payload_size, $messages,
            );
            $sample->{repeat} = $repeat;
            push @samples, $sample;
            $effective_config_by_mode{$mode} //= $effective;
            printf "%s %7d B repeat=%d %11.1f msg/s %9.1f MiB/s cpu=%8.3f ns/B\n",
                $mode, $payload_size, $repeat,
                $sample->{messages_per_second},
                $sample->{mebibytes_per_second},
                $sample->{receiver_cpu_nanoseconds_per_byte};
        }
    }
}

my @summary;
for my $mode (@modes) {
    for my $payload_size (@sizes) {
        my @set = grep {
            $_->{mode} eq $mode && $_->{payload_bytes} == $payload_size
        } @samples;
        push @summary, {
            mode => $mode,
            payload_bytes => $payload_size,
            messages => $set[0]{messages},
            median_messages_per_second => median(
                map { $_->{messages_per_second} } @set),
            median_mebibytes_per_second => median(
                map { $_->{mebibytes_per_second} } @set),
            median_receiver_cpu_nanoseconds_per_byte => median(
                map { $_->{receiver_cpu_nanoseconds_per_byte} } @set),
            median_producer_cpu_nanoseconds_per_byte => median(
                map { $_->{producer_cpu_nanoseconds_per_byte} } @set),
            median_reads_per_message => median(
                map { $_->{reads_per_message} } @set),
            median_writes_per_message => median(
                map { $_->{writes_per_message} } @set),
            median_callbacks_per_message => median(
                map { $_->{callbacks_per_message} } @set),
            median_input_peak_bytes => median(
                map { $_->{input_peak_bytes} } @set),
        };
    }
}

my @uname = uname();
my $report = {
    schema_version => 1,
    benchmark => 'stream-payload-sweep',
    variant => $variant,
    commit => $commit,
    generated_at_epoch => time,
    command => join(' ', $^X, $0, @command_argv),
    runtime => {
        perl => "$^V",
        os => $^O,
        archname => $Config{archname},
        compiler => $Config{cc},
        compiler_flags => $Config{ccflags},
        optimize => $Config{optimize},
        uname => join(' ', @uname),
    },
    configuration => {
        modes => \@modes,
        payload_sizes => \@sizes,
        repeats => $repeats,
        warmups => $warmup,
        target_payload_bytes => $target_bytes,
        minimum_messages => $min_messages,
        maximum_messages => $max_messages,
        read_size => $READ_SIZE,
    },
    effective_config_by_mode => \%effective_config_by_mode,
    samples => \@samples,
    summary => \@summary,
};

make_path(dirname($output));
open my $fh, '>:raw', $output or die "open $output: $!";
print {$fh} JSON::PP->new->canonical->pretty->encode($report);
close $fh or die "close $output: $!";
say "Wrote $output";
