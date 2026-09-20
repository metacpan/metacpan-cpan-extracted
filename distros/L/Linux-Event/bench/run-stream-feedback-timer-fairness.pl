#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use JSON::PP qw(decode_json);
use POSIX qw(WNOHANG _exit);
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC sleep);

use Linux::Event ();
use Linux::Event::Framer;
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::IO::Sock::Stream;

my $read_size = 65_536;
my @budgets = (0, 65_536, 262_144, 1_048_576);
my $timer_after = 1.500;
my $message_bytes = 64;
my $window = 32;
my $warmup = 1;
my $repeats = 3;
my $case_timeout = 5.000;
my $json_path;
my $help;

GetOptions(
    'read-size=i' => \$read_size,
    'budgets=s' => sub { @budgets = map { 0 + $_ } split /,/, $_[1] },
    'timer-after=f' => \$timer_after,
    'message-bytes=i' => \$message_bytes,
    'window=i' => \$window,
    'warmup=i' => \$warmup,
    'repeats=i' => \$repeats,
    'case-timeout=f' => \$case_timeout,
    'json=s' => \$json_path,
    'help' => \$help,
) or usage(1);
usage(0) if $help;

die "read size must be positive\n" if $read_size < 1;
die "budgets must be non-negative\n" if !@budgets || grep { $_ < 0 } @budgets;
die "timer-after must be positive\n" if $timer_after <= 0;
die "message-bytes must be positive\n" if $message_bytes < 1;
die "window must be positive\n" if $window < 1;
die "warmup must be non-negative\n" if $warmup < 0;
die "repeats must be positive\n" if $repeats < 1;
die "case-timeout must exceed timer-after\n" if $case_timeout <= $timer_after;

for my $budget (@budgets) {
    run_guarded_case($budget, 0, 1) for 1 .. $warmup;
}

my @raw;
for my $repeat (1 .. $repeats) {
    my @ordered = rotate(\@budgets, $repeat - 1);
    for my $budget (@ordered) {
        my $row = run_guarded_case($budget, $repeat, 0);
        push @raw, $row;
        if ($row->{outcome} eq 'ok') {
            printf "budget=%-8d repeat=%d timer_late=%10.3f ms rate=%10.0f msg/s read_ready=%7d read_calls=%8d\n",
                $budget, $repeat, $row->{timer_lateness_ms},
                $row->{messages_per_second}, $row->{read_ready_calls},
                $row->{read_calls};
        }
        else {
            printf "budget=%-8d repeat=%d outcome=%s%s\n",
                $budget, $repeat, $row->{outcome},
                defined($row->{error}) ? " error=$row->{error}" : '';
        }
    }
}

my @summary;
for my $budget (@budgets) {
    my @rows = grep { $_->{read_budget_bytes} == $budget } @raw;
    my @ok = grep { $_->{outcome} eq 'ok' } @rows;
    my @timeouts = grep { $_->{outcome} eq 'watchdog_timeout' } @rows;
    my @errors = grep { $_->{outcome} eq 'error' } @rows;
    my $summary = {
        read_budget_bytes => $budget,
        samples => scalar @rows,
        ok_samples => scalar @ok,
        watchdog_timeouts => scalar @timeouts,
        error_samples => scalar @errors,
    };
    if (@ok) {
        $summary->{median_timer_lateness_ms}
            = median(map { $_->{timer_lateness_ms} } @ok);
        $summary->{max_timer_lateness_ms}
            = maximum(map { $_->{timer_lateness_ms} } @ok);
        $summary->{median_messages_per_second}
            = median(map { $_->{messages_per_second} } @ok);
        $summary->{median_read_ready_calls}
            = median(map { $_->{read_ready_calls} } @ok);
        $summary->{median_read_calls}
            = median(map { $_->{read_calls} } @ok);
        $summary->{median_bytes_per_read_ready}
            = median(map { $_->{bytes_per_read_ready} } @ok);
    }
    push @summary, $summary;
}

say "\nStream feedback/timer fairness summary";
printf "read_size=%d timer_after=%.3f message_bytes=%d window=%d repeats=%d\n",
    $read_size, $timer_after, $message_bytes, $window, $repeats;
printf "%-10s %5s %8s %14s %14s %12s %14s\n",
    'budget', 'ok', 'timeout', 'timer late ms', 'messages/s',
    'read ready', 'bytes/ready';
for my $row (@summary) {
    printf "%-10d %5d %8d %14s %14s %12s %14s\n",
        $row->{read_budget_bytes}, $row->{ok_samples},
        $row->{watchdog_timeouts},
        fmt($row->{median_timer_lateness_ms}, 3),
        fmt($row->{median_messages_per_second}, 0),
        fmt($row->{median_read_ready_calls}, 0),
        fmt($row->{median_bytes_per_read_ready}, 0);
}

if (defined $json_path) {
    my $report = {
        benchmark => 'linux-event-stream-feedback-timer-fairness',
        benchmark_contract_version => 1,
        linux_event_version => $Linux::Event::VERSION,
        runtime => {
            perl => "$^V",
            os => $^O,
        },
        configuration => {
            read_size => $read_size,
            read_budgets => \@budgets,
            timer_after_seconds => $timer_after,
            message_bytes => $message_bytes,
            window => $window,
            warmup => $warmup,
            repeats => $repeats,
            case_timeout_seconds => $case_timeout,
            topology => 'Linux::Event Fixed-frame Stream <-> forked blocking AF_UNIX echo peer',
            watchdog => 'outer parent process; independent of Linux::Event',
        },
        raw => \@raw,
        summary => \@summary,
    };
    open my $json, '>:raw', $json_path or die "open $json_path: $!\n";
    print {$json} JSON::PP->new->canonical->pretty->encode($report);
    close $json or die "close $json_path: $!\n";
    say "Wrote $json_path";
}

sub run_guarded_case ($budget, $repeat, $is_warmup) {
    pipe(my $result_read, my $result_write) or die "result pipe: $!";
    my $pid = fork();
    die "case fork: $!" if !defined $pid;

    if ($pid == 0) {
        close $result_read;
        my $row;
        my $ok = eval {
            $row = run_case($budget);
            1;
        };
        if (!$ok) {
            my $error = "$@";
            $error =~ s/\s+\z//;
            $row = {
                outcome => 'error',
                read_budget_bytes => $budget,
                error => $error,
            };
        }
        write_all($result_write, JSON::PP->new->canonical->encode($row));
        close $result_write;
        _exit(0);
    }

    close $result_write;
    my $started = now();
    my $timed_out = 0;
    my $status;
    while (1) {
        my $waited = waitpid($pid, WNOHANG);
        if ($waited == $pid) {
            $status = $?;
            last;
        }
        die "waitpid failed: $!" if $waited < 0;
        if (now() - $started >= $case_timeout) {
            $timed_out = 1;
            kill 'TERM', $pid;
            sleep 0.050;
            my $reaped = waitpid($pid, WNOHANG);
            if ($reaped == 0) {
                kill 'KILL', $pid;
                waitpid($pid, 0);
            }
            $status = $?;
            last;
        }
        sleep 0.005;
    }

    my $payload = '';
    while (1) {
        my $count = sysread($result_read, my $chunk, 65_536);
        if (defined $count) {
            last if $count == 0;
            $payload .= $chunk;
            next;
        }
        next if $!{EINTR};
        die "result read: $!";
    }
    close $result_read;

    return {
        outcome => 'watchdog_timeout',
        read_budget_bytes => $budget,
        repeat => $repeat,
        warmup => $is_warmup ? JSON::PP::true : JSON::PP::false,
        watchdog_elapsed_seconds => now() - $started,
    } if $timed_out;

    if (!defined($status) || $status != 0) {
        return {
            outcome => 'error',
            read_budget_bytes => $budget,
            repeat => $repeat,
            warmup => $is_warmup ? JSON::PP::true : JSON::PP::false,
            error => 'case process exited with status ' . ($status // 'unknown'),
        };
    }

    my $row = eval { decode_json($payload) };
    if (!$row) {
        my $error = "$@";
        $error =~ s/\s+\z//;
        return {
            outcome => 'error',
            read_budget_bytes => $budget,
            repeat => $repeat,
            warmup => $is_warmup ? JSON::PP::true : JSON::PP::false,
            error => "invalid case JSON: $error",
        };
    }
    $row->{repeat} = $repeat;
    $row->{warmup} = $is_warmup ? JSON::PP::true : JSON::PP::false;
    return $row;
}

sub run_case ($budget) {
    socketpair(my $stream_fh, my $peer_fh, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";

    my $peer_pid = fork();
    die "echo peer fork: $!" if !defined $peer_pid;
    if ($peer_pid == 0) {
        close $stream_fh;
        local $SIG{PIPE} = 'IGNORE';
        while (1) {
            my $count = sysread($peer_fh, my $bytes, 262_144);
            if (defined $count) {
                last if $count == 0;
                my $ok = eval {
                    write_all($peer_fh, $bytes);
                    1;
                };
                last if !$ok;
                next;
            }
            next if $!{EINTR};
            last;
        }
        close $peer_fh;
        _exit(0);
    }

    close $peer_fh;

    my $loop = Linux::Event::Loop->new;
    my $state = {
        messages => 0,
        stopping => 0,
    };
    my $class = stream_class($budget);
    my $stream = $class->new(
        loop => $loop,
        fh => $stream_fh,
        data => $state,
    );

    my $timer_fired_at;
    my $scheduled_at = now();
    my $due_at = $scheduled_at + $timer_after;
    my $timer = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        at => $due_at,
        on_timer => sub ($timer) {
            $timer_fired_at = now();
            $state->{stopping} = 1;
            $timer->loop->stop;
        },
    );

    $loop->reset_stats;
    my $payload = 'x' x $message_bytes;
    $stream->send($payload) for 1 .. $window;

    my $run_started = now();
    $loop->run;
    my $run_ended = now();

    my $stream_stats = $stream->{xs_state}->stats;
    my $loop_stats = $loop->stats;
    my $elapsed = $run_ended - $run_started;
    my $read_ready_calls = 0 + $stream_stats->{read_ready_calls};
    my $bytes = 0 + $stream_stats->{bytes_read};

    $state->{stopping} = 1;
    $stream->close if !$stream->is_closed;
    kill 'TERM', $peer_pid;
    waitpid($peer_pid, 0);

    die "timer did not fire\n" if !defined $timer_fired_at;

    return {
        outcome => 'ok',
        read_budget_bytes => $budget,
        timer_due_monotonic => $due_at,
        timer_fired_monotonic => $timer_fired_at,
        timer_lateness_ms => ($timer_fired_at - $due_at) * 1_000,
        elapsed_seconds => $elapsed,
        messages => 0 + $state->{messages},
        messages_per_second => $elapsed > 0
            ? $state->{messages} / $elapsed : 0,
        bytes_read => $bytes,
        read_ready_calls => $read_ready_calls,
        read_calls => 0 + $stream_stats->{read_calls},
        read_eagain_count => 0 + $stream_stats->{read_eagain_count},
        bytes_per_read_ready => $read_ready_calls
            ? $bytes / $read_ready_calls : 0,
        pending_bytes => 0 + $stream_stats->{pending_bytes},
        write_ready_calls => 0 + $stream_stats->{write_ready_calls},
        loop_run_once_calls => 0 + $loop_stats->{run_once_calls},
        loop_epoll_wait_calls => 0 + $loop_stats->{epoll_wait_calls},
        loop_ready_events_returned => 0 + $loop_stats->{ready_events_returned},
        loop_timer_callback_calls => 0 + $loop_stats->{timer_callback_calls},
    };
}

my %STREAM_CLASS;
sub stream_class ($budget) {
    return $STREAM_CLASS{$budget} if exists $STREAM_CLASS{$budget};
    my $class = "Linux::Event::Bench::StreamFeedbackTimerFairness::Budget_$budget";
    my $quoted_class = $class;
    my $code = "package $quoted_class; "
        . "use parent 'Linux::Event::IO::Sock::Stream'; "
        . "use Linux::Event::Framer 'Fixed', size => $message_bytes; 1;";
    eval $code or die "define feedback Stream class: $@";
    {
        no strict 'refs';
        *{"${class}::stream_tuning"} = sub ($class_name) {
            return read_size => $read_size, read_budget_bytes => $budget;
        };
        *{"${class}::on_message"} = sub ($stream, $message) {
            my $data = $stream->data;
            return if $data->{stopping};
            ++$data->{messages};
            $stream->send($message);
            return;
        };
        *{"${class}::on_error"} = sub ($stream, $error) {
            die "Stream error: $error\n";
        };
    }
    $STREAM_CLASS{$budget} = $class;
    return $class;
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
        die "syswrite: $!";
    }
    return;
}

sub rotate ($values, $offset) {
    return @$values if !@$values;
    $offset %= @$values;
    return @$values if $offset == 0;
    return (@$values[$offset .. $#$values], @$values[0 .. $offset - 1]);
}

sub now () { clock_gettime(CLOCK_MONOTONIC) }

sub median (@values) {
    return undef if !@values;
    @values = sort { $a <=> $b } @values;
    my $middle = int(@values / 2);
    return @values % 2
        ? $values[$middle]
        : ($values[$middle - 1] + $values[$middle]) / 2;
}

sub maximum (@values) {
    return undef if !@values;
    my $result = shift @values;
    for my $value (@values) {
        $result = $value if $value > $result;
    }
    return $result;
}

sub fmt ($value, $digits) {
    return '-' if !defined $value;
    return sprintf("%.${digits}f", $value);
}

sub usage ($exit) {
    print <<'USAGE';
Usage: run-stream-feedback-timer-fairness.pl [options]
  --read-size=N          bytes requested by one Stream read (default: 65536)
  --budgets=LIST         read_budget_bytes matrix (default: 0,65536,262144,1048576)
  --timer-after=SECONDS  one-shot Timer target (default: 1.500)
  --message-bytes=N      Fixed-frame payload bytes (default: 64)
  --window=N             messages kept in feedback circulation (default: 32)
  --warmup=N             warmup sweeps (default: 1)
  --repeats=N            measured sweeps (default: 3)
  --case-timeout=SEC     external watchdog per case (default: 5.000)
  --json=PATH            write machine-readable report
  --help                 show this help
USAGE
    exit $exit;
}
