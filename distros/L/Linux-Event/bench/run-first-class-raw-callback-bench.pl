#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use JSON::PP;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC CLOCK_PROCESS_CPUTIME_ID);

use Linux::Event;
use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;

my @read_sizes = (16, 4_096, 65_536);
my @idle_connections = (0, 63);
my $target_mib = 16;
my $minimum_deliveries = 512;
my $repeats = 7;
my $warmup = 1;
my $json_path;
my $help;

GetOptions(
    'read-sizes=s' => sub {
        @read_sizes = map { 0 + $_ } split /,/, $_[1];
    },
    'idle-connections=s' => sub {
        @idle_connections = map { 0 + $_ } split /,/, $_[1];
    },
    'target-mib=f'        => \$target_mib,
    'minimum-deliveries=i' => \$minimum_deliveries,
    'repeats=i'           => \$repeats,
    'warmup=i'            => \$warmup,
    'json=s'              => \$json_path,
    'help'                => \$help,
) or usage(1);
usage(0) if $help;

die "read sizes must be positive\n" if grep { $_ < 1 } @read_sizes;
die "idle connection counts must be non-negative\n"
    if grep { $_ < 0 } @idle_connections;
die "target-mib must be positive\n" if $target_mib <= 0;
die "minimum-deliveries must be positive\n" if $minimum_deliveries < 1;
die "repeats must be positive\n" if $repeats < 1;
die "warmup must be non-negative\n" if $warmup < 0;

{
    package Linux::Event::Bench::RawCachedClosureBase;
    use parent 'Linux::Event::IO::Sock::Stream';

    our %READ_SIZE;
    our ($CAPTURE_A, $CAPTURE_B, $CAPTURE_C, $CAPTURE_D) = (1, 2, 3, 4);

    sub stream_tuning ($class) {
        return read_size => $READ_SIZE{$class}, read_batch_bytes => 0;
    }

    sub on_data ($stream, $bytes) {
        if ($bytes eq '') {
            $CAPTURE_A += $CAPTURE_B + $CAPTURE_C + $CAPTURE_D;
        }
        my $state = $stream->data;
        my $length = length($bytes);
        die "empty raw delivery\n" if !$length;
        die "payload mismatch\n"
            if substr($bytes, 0, 1) ne 'x' || substr($bytes, -1, 1) ne 'x';
        $state->{bytes} += $length;
        $state->{deliveries}++;
        die "received too many bytes\n"
            if $state->{bytes} > $state->{expected_bytes};
        $state->{loop}->stop if $state->{bytes} == $state->{expected_bytes};
        return;
    }

    sub on_error ($stream, $error) {
        die "Stream error: $error\n";
    }
}

our ($PLAIN_A, $PLAIN_B, $PLAIN_C, $PLAIN_D) = (1, 2, 3, 4);

my $plain_coderef = sub ($stream, $bytes) {
    if ($bytes eq '') {
        $PLAIN_A += $PLAIN_B + $PLAIN_C + $PLAIN_D;
    }
    my $state = $stream->data;
    my $length = length($bytes);
    die "empty raw delivery\n" if !$length;
    die "payload mismatch\n"
        if substr($bytes, 0, 1) ne 'x' || substr($bytes, -1, 1) ne 'x';
    $state->{bytes} += $length;
    $state->{deliveries}++;
    die "received too many bytes\n"
        if $state->{bytes} > $state->{expected_bytes};
    $state->{loop}->stop if $state->{bytes} == $state->{expected_bytes};
    return;
};

sub closure_one () {
    my $capture_a = 1;
    return sub ($stream, $bytes) {
        if ($bytes eq '') {
            $capture_a += $PLAIN_B + $PLAIN_C + $PLAIN_D;
        }
        my $state = $stream->data;
        my $length = length($bytes);
        die "empty raw delivery\n" if !$length;
        die "payload mismatch\n"
            if substr($bytes, 0, 1) ne 'x' || substr($bytes, -1, 1) ne 'x';
        $state->{bytes} += $length;
        $state->{deliveries}++;
        die "received too many bytes\n"
            if $state->{bytes} > $state->{expected_bytes};
        $state->{loop}->stop if $state->{bytes} == $state->{expected_bytes};
        return;
    };
}

sub closure_four () {
    my ($capture_a, $capture_b, $capture_c, $capture_d) = (1, 2, 3, 4);
    return sub ($stream, $bytes) {
        if ($bytes eq '') {
            $capture_a += $capture_b + $capture_c + $capture_d;
        }
        my $state = $stream->data;
        my $length = length($bytes);
        die "empty raw delivery\n" if !$length;
        die "payload mismatch\n"
            if substr($bytes, 0, 1) ne 'x' || substr($bytes, -1, 1) ne 'x';
        $state->{bytes} += $length;
        $state->{deliveries}++;
        die "received too many bytes\n"
            if $state->{bytes} > $state->{expected_bytes};
        $state->{loop}->stop if $state->{bytes} == $state->{expected_bytes};
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
for my $read_size (@read_sizes) {
    my $target_bytes = int($target_mib * 1_048_576);
    my $minimum_bytes = $minimum_deliveries * $read_size;
    $target_bytes = $minimum_bytes if $target_bytes < $minimum_bytes;
    $target_bytes = int(($target_bytes + $read_size - 1) / $read_size)
        * $read_size;
    push @configuration, map {
        +{
            read_size => $read_size,
            idle_connections => $_,
            target_bytes => $target_bytes,
        }
    } @idle_connections;
}

for (1 .. $warmup) {
    for my $config (@configuration) {
        my $warm_bytes = int($config->{target_bytes} / 10);
        my $floor = 100 * $config->{read_size};
        $warm_bytes = $floor if $warm_bytes < $floor;
        $warm_bytes = $config->{target_bytes}
            if $warm_bytes > $config->{target_bytes};
        $warm_bytes = int(($warm_bytes + $config->{read_size} - 1)
            / $config->{read_size}) * $config->{read_size};
        for my $case (@case) {
            run_case($case, { %$config, target_bytes => $warm_bytes });
        }
    }
}

my @raw;
for my $repeat (1 .. $repeats) {
    for my $config_index (0 .. $#configuration) {
        my $config = $configuration[$config_index];
        my @ordered = rotate_cases(\@case, $repeat - 1 + $config_index);
        for my $case (@ordered) {
            my $row = run_case($case, $config);
            $row->{repeat} = $repeat;
            push @raw, $row;
            printf "%s read=%d idle=%d repeat=%d %.1f cb/s %.3f cpu us/cb %.1f MiB/s avg=%.1f B/cb\n",
                $case->{name}, $config->{read_size},
                $config->{idle_connections}, $repeat,
                $row->{deliveries_per_second}, $row->{cpu_us_per_delivery},
                $row->{mib_per_second}, $row->{average_bytes_per_delivery};
        }
    }
}

my @summary;
for my $config (@configuration) {
    for my $case (@case) {
        my @rows = grep {
            $_->{case} eq $case->{name}
                && $_->{read_size} == $config->{read_size}
                && $_->{idle_connections} == $config->{idle_connections}
        } @raw;
        my $summary = {
            case => $case->{name},
            read_size => $config->{read_size},
            idle_connections => $config->{idle_connections},
            target_bytes => $config->{target_bytes},
            median_deliveries_per_second => median(
                map { $_->{deliveries_per_second} } @rows,
            ),
            median_cpu_us_per_delivery => median(
                map { $_->{cpu_us_per_delivery} } @rows,
            ),
            median_mib_per_second => median(
                map { $_->{mib_per_second} } @rows,
            ),
            median_average_bytes_per_delivery => median(
                map { $_->{average_bytes_per_delivery} } @rows,
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
                        && $_->{read_size} == $config->{read_size}
                        && $_->{idle_connections}
                            == $config->{idle_connections}
                        && $_->{repeat} == $row->{repeat}
                } @raw;
                push @throughput_delta, 100 * (
                    $row->{deliveries_per_second}
                        / $paired_method->{deliveries_per_second} - 1
                );
                push @cpu_delta, 100 * (
                    $row->{cpu_us_per_delivery}
                        / $paired_method->{cpu_us_per_delivery} - 1
                );
            }
            $summary->{throughput_delta_percent} = median(@throughput_delta);
            $summary->{cpu_delta_percent} = median(@cpu_delta);
        }
        push @summary, $summary;
    }
}

say "\nFirst-class raw callback dispatch benchmark";
printf "target_mib=%.3f minimum_deliveries=%d warmup=%d repeats=%d\n",
    $target_mib, $minimum_deliveries, $warmup, $repeats;
printf "%-20s %8s %6s %12s %12s %10s %10s %10s\n",
    'case', 'read', 'idle', 'cb/s', 'cpu us/cb', 'MiB/s', 'speed', 'cpu';
for my $row (@summary) {
    printf "%-20s %8d %6d %12.1f %12.3f %10.1f %9s %9s\n",
        $row->{case}, $row->{read_size}, $row->{idle_connections},
        $row->{median_deliveries_per_second},
        $row->{median_cpu_us_per_delivery},
        $row->{median_mib_per_second},
        defined($row->{throughput_delta_percent})
            ? sprintf('%+.2f%%', $row->{throughput_delta_percent}) : '-',
        defined($row->{cpu_delta_percent})
            ? sprintf('%+.2f%%', $row->{cpu_delta_percent}) : '-';
}

if (defined $json_path) {
    my $report = {
        benchmark => 'linux-event-first-class-raw-callback-dispatch',
        benchmark_contract_version => 1,
        linux_event_version => $Linux::Event::VERSION,
        perl_version => 0 + $],
        configuration => {
            read_sizes => \@read_sizes,
            idle_connections => \@idle_connections,
            target_mib => 0 + $target_mib,
            minimum_deliveries => $minimum_deliveries,
            repeats => $repeats,
            warmup => $warmup,
            read_batch_bytes => 0,
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

    my $writer = fork();
    die "writer fork: $!" if !defined $writer;
    if ($writer == 0) {
        close $receiver;
        close $gate_write;
        my $gate = '';
        sysread($gate_read, $gate, 1) == 1 or exit 2;
        close $gate_read;
        local $SIG{PIPE} = 'IGNORE';
        eval { write_bytes($sender, $config->{target_bytes}); 1 }
            or exit 3;
        close $sender;
        exit 0;
    }

    close $sender;
    close $gate_read;
    my $loop = Linux::Event::Loop->new;
    my $state = {
        loop => $loop,
        bytes => 0,
        deliveries => 0,
        expected_bytes => $config->{target_bytes},
    };
    my $class = raw_class_for($config->{read_size});
    my $callback = $case->{callback}->();
    my %callback_option = defined($callback) ? (on_data => $callback) : ();
    my @streams;
    my @idle_peers;
    my $rss_before_setup = current_rss_kib();
    my $setup_start = clock_gettime(CLOCK_MONOTONIC);
    push @streams, $class->new(
        loop => $loop,
        fh => $receiver,
        data => $state,
        %callback_option,
    );
    for (1 .. $config->{idle_connections}) {
        socketpair(my $idle_stream, my $idle_peer,
            AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
        push @idle_peers, $idle_peer;
        push @streams, $class->new(
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

    local $SIG{ALRM} = sub { die "first-class raw callback benchmark timed out\n" };
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
    die "received $state->{bytes} bytes, expected $config->{target_bytes}\n"
        if $state->{bytes} != $config->{target_bytes};
    die "native read count is $stats->{bytes_read}, expected $config->{target_bytes}\n"
        if $stats->{bytes_read} != $config->{target_bytes};
    die "native delivery count is $stats->{delivery_calls}, callback saw $state->{deliveries}\n"
        if $stats->{delivery_calls} != $state->{deliveries};
    die "raw path unexpectedly emitted frames\n" if $stats->{frames_emitted};
    die "raw path delivered no callbacks\n" if !$state->{deliveries};

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
        read_size => $config->{read_size},
        idle_connections => $config->{idle_connections},
        target_bytes => $config->{target_bytes},
        deliveries => $state->{deliveries},
        elapsed_seconds => 0 + $elapsed,
        receiver_cpu_seconds => 0 + $cpu,
        deliveries_per_second => $state->{deliveries} / $elapsed,
        cpu_us_per_delivery => $cpu * 1_000_000 / $state->{deliveries},
        mib_per_second => ($config->{target_bytes} / 1_048_576) / $elapsed,
        average_bytes_per_delivery => $config->{target_bytes}
            / $state->{deliveries},
        setup_us_per_stream => ($setup_end - $setup_start) * 1_000_000
            / $stream_count,
        rss_before_setup_kib => $rss_before_setup,
        rss_after_setup_kib => $rss_after_setup,
        rss_setup_delta_kib => $rss_after_setup - $rss_before_setup,
        read_calls => $stats->{read_calls},
        read_eagain_count => $stats->{read_eagain_count},
        bytes_read => $stats->{bytes_read},
        frames_emitted => $stats->{frames_emitted},
        callback_calls => $stats->{delivery_calls},
    };
}

sub raw_class_for ($read_size) {
    my $class = "Linux::Event::Bench::RawCachedClosureStream::R$read_size";
    no strict 'refs';
    if (!@{"${class}::ISA"}) {
        @{"${class}::ISA"} = ('Linux::Event::Bench::RawCachedClosureBase');
        $Linux::Event::Bench::RawCachedClosureBase::READ_SIZE{$class}
            = $read_size;
    }
    return $class;
}

sub write_bytes ($fh, $total) {
    my $chunk = 'x' x 65_536;
    my $remaining = $total;
    while ($remaining) {
        my $length = $remaining < length($chunk) ? $remaining : length($chunk);
        write_all($fh, substr($chunk, 0, $length));
        $remaining -= $length;
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
  perl -Iblib/lib -Iblib/arch bench/run-first-class-raw-callback-bench.pl [options]

Options:
  --read-sizes=16,4096,65536
  --idle-connections=0,63
  --target-mib=16
  --minimum-deliveries=512
  --repeats=7
  --warmup=1
  --json=path

The benchmark compares one cached subclass on_data CV with a cached constructor
coderef, a closure retaining one lexical, and a closure retaining four
lexicals. Every case uses raw native delivery with read_batch_bytes=0 and the
same executed callback work. Cases rotate within each repeated configuration.
Receiver process CPU excludes the forked blocking writer. Because SOCK_STREAM
read chunking is not message preserving, actual callback counts and average
bytes per callback are recorded and native byte/delivery counters are checked.
USAGE
    exit $status;
}
