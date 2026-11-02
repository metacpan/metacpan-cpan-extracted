#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Temp ();
use JSON::PP qw(encode_json decode_json);
use Socket qw(SOL_SOCKET SO_SNDBUF);
use IO::Socket::INET;
use Digest::SHA qw(sha256_hex);
use Time::HiRes qw(time clock_gettime CLOCK_PROCESS_CPUTIME_ID usleep);
use POSIX qw(_exit);

use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::IO::Sock::Stream;

{
    package T::StreamSendfileBench;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) {
        return high_watermark => 262144, low_watermark => 65536,
            max_pending_bytes => 0;
    }
    sub on_data ($self, $bytes) { }
    sub on_drain ($self) {
        my $pump = $self->data->{pump};
        $pump->() if $pump;
    }
    sub on_eof ($self) {
        $self->data->{stats} = $self->{xs_state}->stats if $self->{xs_state};
    }
    sub on_error ($self, $error) {
        $self->data->{error} = "$error";
        $self->data->{loop}->stop;
    }
    sub on_close ($self) { $self->data->{loop}->stop }
}

sub make_source ($body) {
    my $fh = File::Temp->new(UNLINK => 1);
    binmode($fh);
    my $pos = 0;
    while ($pos < length($body)) {
        my $n = syswrite($fh, $body, length($body) - $pos, $pos);
        die "source write: $!" if !defined($n) || $n == 0;
        $pos += $n;
    }
    seek($fh, 0, 0) or die "source seek: $!";
    return $fh;
}

sub process_cpu () {
    return clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
}

sub test_case ($mode, $size, $pressure_us, $tick_us, $budget_bytes) {
    my $body = substr(('0123456789abcdef' x int(($size + 15) / 16)), 0, $size);
    my $sha = sha256_hex($body);
    my $source = make_source($body);
    my $listen = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp',
        Listen => 1, ReuseAddr => 1,
    ) or die "TCP listen: $!";
    my $out = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $listen->sockport,
        Proto => 'tcp',
    ) or die "TCP connect: $!";
    my $in = $listen->accept or die "TCP accept: $!";
    close $listen;
    setsockopt($out, SOL_SOCKET, SO_SNDBUF, pack('i', 65536))
        or die "setsockopt SO_SNDBUF: $!";
    pipe(my $report_read, my $report_write) or die "pipe: $!";

    my $pid = fork();
    die "fork: $!" if !defined($pid);
    if ($pid == 0) {
        close $report_read;
        close $out;
        close $source;
        my $start_cpu = process_cpu();
        my $digest = Digest::SHA->new(256);
        my $read_total = 0;
        for (;;) {
            my $chunk = '';
            my $n = sysread($in, $chunk, 65536);
            _exit(23) if !defined $n;
            last if $n == 0;
            $digest->add($chunk);
            $read_total += $n;
            usleep($pressure_us) if $pressure_us;
        }
        my $report = encode_json({
            bytes => $read_total,
            sha256 => $digest->hexdigest,
            receiver_cpu_sec => process_cpu() - $start_cpu,
        }) . "\n";
        print {$report_write} $report;
        close $report_write;
        close $in;
        _exit(0);
    }

    close $report_write;
    close $in;
    my $loop = Linux::Event::Loop->new;
    my $state = { loop => $loop, error => undef, stats => undef, pump => undef };
    my $stream = T::StreamSendfileBench->new(
        loop => $loop, fh => $out, data => $state,
    );
    my $start_wall = time;
    my $start_cpu = process_cpu();
    my @timer_late_ms;
    my $timer;
    if ($tick_us) {
        $timer = Linux::Event::Kernel::Timer->new(
            loop => $loop, every => $tick_us / 1_000_000,
            on_timer => sub ($self) {
                # Recurring Timers publish their *next* deadline before
                # invoking on_timer. Reconstruct the represented due time.
                my $due = $self->deadline
                    - $self->expirations * $self->interval;
                my $late_ms = 1000
                    * (Linux::Event::Kernel::Timer->now - $due);
                push @timer_late_ms, $late_ms > 0 ? $late_ms : 0;
            },
        );
    }

    if ($mode eq 'sendfile') {
        $stream->sendfile($source);
        $stream->end;
    } elsif ($mode eq 'preloaded') {
        $stream->write($body);
        $stream->end;
    } elsif ($mode eq 'copy') {
        my $left = $size;
        my $inside = 0;
        my $pump;
        $pump = sub {
            return if $inside++;
            while (!$stream->is_closed) {
                if (!$left) {
                    $state->{pump} = undef;
                    $stream->end;
                    last;
                }
                my $chunk = '';
                my $count = $left < 65536 ? $left : 65536;
                my $n = sysread($source, $chunk, $count);
                die "source read: $!" if !defined($n) || $n == 0;
                $left -= $n;
                last if !$stream->write($chunk);
            }
            $inside = 0;
        };
        $state->{pump} = $pump;
        $pump->();
    } else {
        die "unknown mode: $mode";
    }

    $loop->run_for(30) unless $stream->is_closed;
    $timer->cancel if $timer && $timer->is_active;
    my $sender_cpu = process_cpu() - $start_cpu;
    $stream->close if !$stream->is_closed;
    waitpid($pid, 0);
    my $child_status = $?;
    my $wall = time - $start_wall;
    my $report = <$report_read>;
    close $report_read;
    close $source;

    die "Stream failed: $state->{error}" if $state->{error};
    die "receiver failed (status $child_status)" if $child_status != 0;
    die "missing receiver report" if !defined($report);
    my $received = decode_json($report);
    die "byte count mismatch for $mode: $received->{bytes} != $size"
        if $received->{bytes} != $size;
    die "SHA-256 mismatch for $mode at $size bytes"
        if $received->{sha256} ne $sha;

    my $mib = $size / 1048576;
    my $stats = $state->{stats} // {};
    my @sorted_late = sort { $a <=> $b } @timer_late_ms;
    my $p95 = @sorted_late
        ? $sorted_late[int(0.95 * (@sorted_late - 1))] : undef;
    my $max_late = @sorted_late ? $sorted_late[-1] : undef;
    return {
        mode => $mode,
        budget_bytes => $budget_bytes,
        timer_interval_us => $tick_us,
        timer_samples => scalar(@timer_late_ms),
        timer_late_p95_ms => $p95,
        timer_late_max_ms => $max_late,
        bytes => $size,
        receiver_delay_us => $pressure_us,
        verified => JSON::PP::true,
        wall_sec => $wall,
        sender_cpu_sec => $sender_cpu,
        receiver_cpu_sec => $received->{receiver_cpu_sec},
        sender_cpu_ms_per_mib => $sender_cpu * 1000 / $mib,
        receiver_cpu_ms_per_mib => $received->{receiver_cpu_sec} * 1000 / $mib,
        throughput_mib_s => $mib / $wall,
        eagain_count => $stats->{write_eagain_count},
        queue_peak_bytes => $stats->{queue_peak_bytes},
        write_calls => $stats->{write_calls},
        writev_calls => $stats->{writev_calls},
    };
}

my $sizes = '64,4096,32768,204800,1048576,8388608';
my $repeats = 3;
my $pressure_us = 0;
my $jsonl = '';
my $tick_us = 0;
my $budget_bytes = 65536;
GetOptions(
    'sizes=s' => \$sizes,
    'repeats=i' => \$repeats,
    'pressure-us=i' => \$pressure_us,
    'jsonl=s' => \$jsonl,
    'tick-us=i' => \$tick_us,
    'budget-bytes=i' => \$budget_bytes,
) or die "usage: $0 [--sizes=64,4096,...] [--repeats=3] [--pressure-us=0] [--jsonl=path]\n";
die "repeats must be >= 1\n" if $repeats < 1;
die "pressure-us must be >= 0\n" if $pressure_us < 0;
die "tick-us must be >= 0\n" if $tick_us < 0;
die "budget-bytes must be positive\n" if $budget_bytes < 1;
my @sizes = split /,/, $sizes;
for my $size (@sizes) {
    die "sizes must be positive integer bytes\n"
        if $size !~ /\A[1-9][0-9]*\z/;
}

my $output;
if (length($jsonl)) {
    open $output, '>', $jsonl or die "open $jsonl: $!";
} else {
    $output = *STDOUT;
}
my @modes = qw(sendfile copy preloaded);
for my $size (@sizes) {
    for my $rep (0 .. $repeats - 1) {
        for my $i (0 .. 2) {
            my $mode = $modes[($rep + $i) % 3];
            my $result = test_case($mode, $size, $pressure_us,
                $tick_us, $budget_bytes);
            $result->{repetition} = $rep + 1;
            print {$output} encode_json($result), "\n";
        }
    }
}
close($output) if length($jsonl);
