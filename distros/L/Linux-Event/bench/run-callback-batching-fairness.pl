#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use IO::Socket::INET;
use JSON::PP;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC usleep);

use Linux::Event;
use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;

my $duration = 0.5;
my $ping_interval_us = 2_000;
my $payload_bytes = 64;
my $read_size = 4_096;
my @batch_sizes = (0, 4, 16, 64, 256);
my @transports = qw(unix tcp);
my $warmup = 1;
my $repeats = 5;
my $json_path;
my $help;

GetOptions(
    'duration=f'       => \$duration,
    'ping-interval-us=i' => \$ping_interval_us,
    'bytes=i'          => \$payload_bytes,
    'read-size=i'      => \$read_size,
    'batch-sizes=s'    => sub {
        @batch_sizes = map { 0 + $_ } split /,/, $_[1];
    },
    'transports=s'     => sub { @transports = split /,/, $_[1] },
    'warmup=i'         => \$warmup,
    'repeats=i'        => \$repeats,
    'json=s'           => \$json_path,
    'help'             => \$help,
) or usage(1);
usage(0) if $help;
die "duration must be positive\n" if $duration <= 0;
die "ping interval must be positive\n" if $ping_interval_us < 1;
die "bytes must be positive\n" if $payload_bytes < 1;
die "read size must be positive\n" if $read_size < 1;
die "warmup must be non-negative\n" if $warmup < 0;
die "repeats must be positive\n" if $repeats < 1;
die "batch sizes must be non-negative\n" if grep { $_ < 0 } @batch_sizes;
my %valid_transport = map { $_ => 1 } qw(unix tcp);
die "unknown transport\n" if grep { !$valid_transport{$_} } @transports;

my @cases = map {
    my $transport = $_;
    map { +{ transport => $transport, batch_size => $_ } } @batch_sizes;
} @transports;

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
        printf "%s batch=%d repeat=%d hot=%.1f MiB/s ping p99=%.1f us max=%.1f us n=%d\n",
            $case->{transport}, $case->{batch_size}, $repeat,
            $row->{hot_payload_mib_per_second}, $row->{ping_p99_us},
            $row->{ping_max_us}, $row->{ping_count};
    }
}

my @summary;
for my $case (@cases) {
    my @rows = grep {
        $_->{transport} eq $case->{transport}
            && $_->{batch_size} == $case->{batch_size}
    } @raw;
    push @summary, {
        %$case,
        median_hot_payload_mib_per_second => median(
            map { $_->{hot_payload_mib_per_second} } @rows,
        ),
        median_ping_p50_us => median(map { $_->{ping_p50_us} } @rows),
        median_ping_p99_us => median(map { $_->{ping_p99_us} } @rows),
        median_ping_max_us => median(map { $_->{ping_max_us} } @rows),
        median_ping_count => median(map { $_->{ping_count} } @rows),
        median_hot_callback_calls => median(
            map { $_->{hot_callback_calls} } @rows,
        ),
    };
}

say "\nCallback batching fairness benchmark";
printf "duration=%.3f ping_interval_us=%d payload=%d read_size=%d repeats=%d\n",
    $duration, $ping_interval_us, $payload_bytes, $read_size, $repeats;
printf "%-6s %8s %12s %12s %12s %12s %12s\n",
    'xport', 'batch', 'hot MiB/s', 'ping p50', 'ping p99', 'ping max',
    'hot cb';
for my $row (@summary) {
    printf "%-6s %8d %12.1f %12.1f %12.1f %12.1f %12.0f\n",
        $row->{transport}, $row->{batch_size},
        $row->{median_hot_payload_mib_per_second},
        $row->{median_ping_p50_us}, $row->{median_ping_p99_us},
        $row->{median_ping_max_us}, $row->{median_hot_callback_calls};
}

if (defined $json_path) {
    my $report = {
        benchmark => 'linux-event-callback-batching-fairness',
        benchmark_contract_version => 1,
        linux_event_version => $Linux::Event::VERSION,
        configuration => {
            duration => $duration,
            ping_interval_us => $ping_interval_us,
            bytes => $payload_bytes,
            read_size => $read_size,
            batch_sizes => \@batch_sizes,
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
    my ($hot_receiver, $hot_sender) = connected_pair($case->{transport});
    my ($ping_receiver, $ping_sender) = connected_pair($case->{transport});
    pipe(my $gate_read, my $gate_write) or die "gate pipe: $!";

    my $payload = 'x' x $payload_bytes;
    my $hot_wire = ($payload . "\n") x 1_000;
    my $hot_pid = fork();
    die "hot producer fork: $!" if !defined $hot_pid;
    if ($hot_pid == 0) {
        close $hot_receiver;
        close $ping_receiver;
        close $ping_sender;
        close $gate_write;
        my $gate = '';
        sysread($gate_read, $gate, 1) == 1 or exit 2;
        close $gate_read;
        my $deadline = now() + $duration;
        local $SIG{PIPE} = 'IGNORE';
        while (now() < $deadline) {
            last if !eval { write_all($hot_sender, $hot_wire); 1 };
        }
        close $hot_sender;
        exit 0;
    }

    my $ping_pid = fork();
    die "ping producer fork: $!" if !defined $ping_pid;
    if ($ping_pid == 0) {
        close $hot_receiver;
        close $hot_sender;
        close $ping_receiver;
        close $gate_write;
        my $gate = '';
        sysread($gate_read, $gate, 1) == 1 or exit 2;
        close $gate_read;
        my $deadline = now() + $duration;
        local $SIG{PIPE} = 'IGNORE';
        while (now() < $deadline) {
            last if !eval { write_all($ping_sender, pack('d', now())); 1 };
            usleep($ping_interval_us);
        }
        close $ping_sender;
        exit 0;
    }

    close $hot_sender;
    close $ping_sender;
    close $gate_read;
    my $loop = Linux::Event::Loop->new;
    my $shared = { loop => $loop, eof => 0, latencies => [] };
    my $hot_state = { shared => $shared, messages => 0 };
    my $ping_state = { shared => $shared };
    my $hot_class = hot_class($case->{batch_size});
    my $hot = $hot_class->new(
        loop => $loop, fh => $hot_receiver, data => $hot_state,
    );
    my $ping = Linux::Event::Bench::BatchFairness::Ping->new(
        loop => $loop, fh => $ping_receiver, data => $ping_state,
    );

    my $started = now();
    syswrite($gate_write, 'gg') == 2 or die "release producers: $!";
    close $gate_write;
    local $SIG{ALRM} = sub { die "fairness benchmark timed out\n" };
    alarm int($duration + 10);
    my $ok = eval { $loop->run; 1 };
    my $error = $@;
    alarm 0;
    my $elapsed = now() - $started;
    if (!$ok) {
        kill 'TERM', $hot_pid, $ping_pid;
        waitpid($hot_pid, 0);
        waitpid($ping_pid, 0);
        die $error;
    }
    waitpid($hot_pid, 0);
    my $hot_status = $?;
    waitpid($ping_pid, 0);
    my $ping_status = $?;
    die "hot producer failed with status $hot_status\n" if $hot_status != 0;
    die "ping producer failed with status $ping_status\n" if $ping_status != 0;

    my @latency = sort { $a <=> $b } @{ $shared->{latencies} };
    die "fairness benchmark received no pings\n" if !@latency;
    my $stats = $hot->{xs_state}->stats;
    my $hot_payload_bytes = $hot_state->{messages} * $payload_bytes;
    my $hot_callbacks = $stats->{message_callback_calls}
        + $stats->{message_batch_calls};
    $hot->close if !$hot->is_closed;
    $ping->close if !$ping->is_closed;
    return {
        %$case,
        elapsed_seconds => $elapsed,
        hot_messages => $hot_state->{messages},
        hot_payload_mib_per_second =>
            ($hot_payload_bytes / 1_048_576) / $elapsed,
        hot_callback_calls => $hot_callbacks,
        ping_count => scalar @latency,
        ping_p50_us => percentile(\@latency, 0.50),
        ping_p99_us => percentile(\@latency, 0.99),
        ping_max_us => $latency[-1],
    };
}

{
    package Linux::Event::Bench::BatchFairness::Ping;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Fixed', size => 8;
    sub on_message ($stream, $message) {
        my $sent = unpack('d', $message);
        push @{ $stream->data->{shared}{latencies} },
            (main::now() - $sent) * 1_000_000;
    }
    sub on_eof ($stream) { main::note_eof($stream) }
}

my %hot_class;
sub hot_class ($batch_size) {
    return $hot_class{$batch_size} if $hot_class{$batch_size};
    my $class = "Linux::Event::Bench::BatchFairness::Hot_$batch_size";
    eval qq{
        package $class;
        use parent 'Linux::Event::IO::Sock::Stream';
        use Linux::Event::Framer 'Delimiter', "\\n";
        1;
    } or die "define hot Stream class: $@";
    no strict 'refs';
    *{"${class}::stream_tuning"} = sub ($class_name) {
        return read_size => $read_size, message_batch_size => $batch_size;
    };
    if ($batch_size) {
        *{"${class}::on_messages"} = sub ($stream, $messages) {
            $stream->data->{messages} += scalar @$messages;
        };
    } else {
        *{"${class}::on_message"} = sub ($stream, $message) {
            $stream->data->{messages}++;
        };
    }
    *{"${class}::on_eof"} = sub ($stream) { main::note_eof($stream) };
    $hot_class{$batch_size} = $class;
    return $class;
}

sub note_eof ($stream) {
    my $shared = $stream->data->{shared};
    $shared->{eof}++;
    $shared->{loop}->stop if $shared->{eof} == 2;
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

sub write_all ($fh, $bytes) {
    my $offset = 0;
    while ($offset < length($bytes)) {
        my $written = syswrite($fh, $bytes, length($bytes) - $offset, $offset);
        if (defined $written) { $offset += $written; next }
        next if $!{EINTR};
        die "producer syswrite: $!";
    }
}

sub now () { clock_gettime(CLOCK_MONOTONIC) }

sub percentile ($values, $fraction) {
    my $index = int($fraction * (@$values - 1) + 0.5);
    return $values->[$index];
}

sub median (@values) {
    @values = sort { $a <=> $b } @values;
    my $middle = int(@values / 2);
    return @values % 2
        ? $values[$middle]
        : ($values[$middle - 1] + $values[$middle]) / 2;
}

sub rotate_cases ($cases, $offset) {
    return @$cases if !@$cases;
    $offset %= @$cases;
    return (@$cases[$offset .. $#$cases], @$cases[0 .. $offset - 1]);
}

sub usage ($exit) {
    print <<'USAGE';
Usage: run-callback-batching-fairness.pl [options]
  --duration=SECONDS        producer duration per case (default: 0.5)
  --ping-interval-us=N      latency probe interval (default: 2000)
  --bytes=N                 hot payload bytes (default: 64)
  --read-size=N             native syscall read size (default: 4096)
  --batch-sizes=LIST        zero or frame limits (default: 0,4,16,64,256)
  --transports=LIST         unix,tcp (default: unix,tcp)
  --warmup=N                untimed case sweeps (default: 1)
  --repeats=N               measured sweeps (default: 5)
  --json=PATH               write machine-readable report
  --help                    show this help
USAGE
    exit $exit;
}
