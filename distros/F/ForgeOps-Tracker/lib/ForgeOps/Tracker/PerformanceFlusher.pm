package ForgeOps::Tracker::PerformanceFlusher;

use strict;
use warnings;
use threads;
use threads::shared;
use Time::HiRes ();
use POSIX qw(strftime);

# Times requests in-process, bucketed by transaction name (see the PSGI/Dancer2 performance
# integrations), and periodically flushes each distinct bucket as one small aggregate report,
# rather than one network call per request. Ported directly from
# gems/forge_ops_tracker/lib/forge_ops_tracker/performance_flusher.rb: like Go's own
# PerformanceFlusher, there's no existing session-tracking/aggregate-flusher precedent in this
# client to mirror the shape of (this SDK has never had a session tracking feature), so this
# borrows DeliveryQueue's own lazy-thread-start idiom instead (see that module's own comment),
# just clock-triggered (a periodic sleep-then-flush loop) rather than push-triggered (a
# Thread::Queue consumer).
#
# Perl's ithreads share nothing by default, so the buckets this flusher aggregates into have to
# be threads::shared explicitly to stay visible to (and safely mutable from) both the thread(s)
# calling record() and the background thread that flushes them. Kept as three parallel flat
# shared hashes (counts / duration sums / max durations), rather than one shared hash of hashrefs,
# since threads::shared has to share nested structures explicitly and three flat shared hashes
# sidestep that entirely; a single shared scalar ($self->{lock}) guards every read-modify-write of
# all three together.
sub new {
    my ($class, $configuration, $client) = @_;

    my %counts :shared;
    my %duration_sums :shared;
    my %max_durations :shared;
    my $lock = 1;
    share($lock);
    my $period_started_at;
    share($period_started_at);
    $period_started_at = Time::HiRes::time;

    return bless {
        configuration      => $configuration,
        client             => $client,
        counts             => \%counts,
        duration_sums      => \%duration_sums,
        max_durations      => \%max_durations,
        lock               => \$lock,
        period_started_at  => \$period_started_at,
        worker             => undef,
    }, $class;
}

# Buckets one request's own duration under transaction_name.
sub record {
    my ($self, $transaction_name, $duration_ms) = @_;
    my $config = $self->{configuration};
    return unless $config->{track_performance} && $config->is_enabled;

    $self->_ensure_worker;

    lock(${ $self->{lock} });
    $self->{counts}{$transaction_name}++;
    $self->{duration_sums}{$transaction_name} += $duration_ms;
    if (!defined($self->{max_durations}{$transaction_name})
        || $duration_ms > $self->{max_durations}{$transaction_name}) {
        $self->{max_durations}{$transaction_name} = $duration_ms;
    }
}

# Snapshots and resets the buffered buckets, then delivers them as one batch. A failed delivery
# keeps every bucket where it is rather than resetting, so the next flush's batch just grows
# instead of losing what was already tallied; there's no other copy of this data anywhere.
sub flush {
    my ($self) = @_;

    my (@names, %counts_snapshot, %sums_snapshot, %max_snapshot, $period_started_at, $period_ended_at);
    {
        lock(${ $self->{lock} });
        @names = keys %{ $self->{counts} };
        return unless @names;

        $period_started_at = ${ $self->{period_started_at} };
        $period_ended_at = Time::HiRes::time;
        %counts_snapshot = %{ $self->{counts} };
        %sums_snapshot = %{ $self->{duration_sums} };
        %max_snapshot = %{ $self->{max_durations} };
    }

    my $config = $self->{configuration};
    my @samples = map {
        {
            transaction_name  => $_,
            environment       => $config->{environment},
            release           => $config->{release},
            period_started_at => _format_time($period_started_at),
            period_ended_at   => _format_time($period_ended_at),
            request_count     => $counts_snapshot{$_} + 0,
            duration_sum_ms   => $sums_snapshot{$_} + 0,
            max_duration_ms   => $max_snapshot{$_} + 0,
        }
    } @names;

    my $delivered = $self->{client}->deliver_performance_samples(\@samples);
    return unless $delivered;

    lock(${ $self->{lock} });
    %{ $self->{counts} } = ();
    %{ $self->{duration_sums} } = ();
    %{ $self->{max_durations} } = ();
    ${ $self->{period_started_at} } = $period_ended_at;
}

sub _ensure_worker {
    my ($self) = @_;
    return if $self->{worker};

    my $flusher = $self;
    $self->{worker} = threads->create(sub {
        while (1) {
            my $interval = $flusher->{configuration}{performance_flush_interval};
            $interval = 60 unless $interval && $interval > 0;
            sleep($interval);

            # Per-tick, not left to kill the loop: one bad flush must not stop every flush after
            # it. Also guards against a logger callback that didn't clone cleanly into this thread
            # (the same known ithreads sharp edge DeliveryQueue's own worker already documents).
            eval { $flusher->flush };
            if ($@) {
                eval { $flusher->{configuration}->log("[forge-ops-tracker] performance flush error: $@") };
            }
        }
    });
    $self->{worker}->detach;
}

# ISO 8601 in UTC, matching every other SDK's own period_started_at/period_ended_at format.
sub _format_time {
    my ($epoch_seconds) = @_;
    my $whole = int($epoch_seconds);
    my $fraction = $epoch_seconds - $whole;
    return strftime('%Y-%m-%dT%H:%M:%S', gmtime($whole)) . sprintf('.%03dZ', int($fraction * 1000));
}

1;
