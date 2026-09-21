package ForgeOps::Tracker::PerformanceFlusher;

use strict;
use warnings;
use threads;
use threads::shared;
use Time::HiRes ();
use POSIX qw(strftime);
use ForgeOps::Tracker::HistogramBucketer;

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
# calling record() and the background thread that flushes them. Kept as four parallel flat
# shared hashes (counts / duration sums / max durations / histogram counts), rather than one shared
# hash of hashrefs, since threads::shared has to share nested structures explicitly and flat shared
# hashes sidestep that entirely (the histogram hash is keyed "transaction_name<US>bucket_label",
# where <US> is the ASCII unit separator, see HISTOGRAM_KEY_SEPARATOR); a single shared scalar
# ($self->{lock}) guards every read-modify-write of all four together.
use constant HISTOGRAM_KEY_SEPARATOR => "\x1F";

sub new {
    my ($class, $configuration, $client) = @_;

    my %counts :shared;
    my %duration_sums :shared;
    my %max_durations :shared;
    my %histogram_counts :shared;
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
        histogram_counts   => \%histogram_counts,
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
    # The distribution count/sum/max can't reconstruct: see HistogramBucketer for why the server
    # approximates a percentile from these bucket counts.
    my $histogram_key = join(HISTOGRAM_KEY_SEPARATOR, $transaction_name,
        ForgeOps::Tracker::HistogramBucketer::bucket_for($duration_ms));
    $self->{histogram_counts}{$histogram_key}++;
}

# Snapshots the buffered buckets, then delivers them as one batch. A failed delivery keeps every
# bucket where it is rather than resetting, so the next flush's batch just grows instead of losing
# what was already tallied; there's no other copy of this data anywhere.
#
# Only exactly what this snapshot delivered is removed afterward, subtracted from whatever is in
# each bucket by then, never everything cleared: record() can run on another thread while delivery
# is in flight (the lock is released around the network call), so a record for a transaction already
# in the snapshot, or a brand-new one, can land between the snapshot and delivery succeeding, and
# clearing afterward would silently discard it. max_durations is left as whatever is currently on
# the bucket, sent or not: a max can't be "subtracted" back out, and leaving it never overstates
# the next period's own max.
sub flush {
    my ($self) = @_;

    my (@names, %counts_snapshot, %sums_snapshot, %max_snapshot, %histogram_snapshot, $period_started_at, $period_ended_at);
    {
        lock(${ $self->{lock} });
        @names = keys %{ $self->{counts} };
        return unless @names;

        $period_started_at = ${ $self->{period_started_at} };
        $period_ended_at = Time::HiRes::time;
        %counts_snapshot = %{ $self->{counts} };
        %sums_snapshot = %{ $self->{duration_sums} };
        %max_snapshot = %{ $self->{max_durations} };
        %histogram_snapshot = %{ $self->{histogram_counts} };
    }

    my %histogram_by_name;
    for my $key (keys %histogram_snapshot) {
        my ($name, $label) = split /\x1F/, $key, 2;
        $histogram_by_name{$name}{$label} = $histogram_snapshot{$key} + 0;
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
            histogram         => $histogram_by_name{$_} || {},
        }
    } @names;

    my $delivered = $self->{client}->deliver_performance_samples(\@samples);
    return unless $delivered;

    lock(${ $self->{lock} });
    for my $key (keys %histogram_snapshot) {
        next unless exists $self->{histogram_counts}{$key};
        my $remaining = $self->{histogram_counts}{$key} - $histogram_snapshot{$key};
        if ($remaining > 0) {
            $self->{histogram_counts}{$key} = $remaining;
        } else {
            delete $self->{histogram_counts}{$key};
        }
    }
    for my $name (@names) {
        next unless exists $self->{counts}{$name};
        $self->{counts}{$name} -= $counts_snapshot{$name};
        my $remaining_sum = $self->{duration_sums}{$name} - $sums_snapshot{$name};
        $self->{duration_sums}{$name} = $remaining_sum > 0 ? $remaining_sum : 0;
        if ($self->{counts}{$name} <= 0) {
            delete $self->{counts}{$name};
            delete $self->{duration_sums}{$name};
            delete $self->{max_durations}{$name};
        }
    }
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
