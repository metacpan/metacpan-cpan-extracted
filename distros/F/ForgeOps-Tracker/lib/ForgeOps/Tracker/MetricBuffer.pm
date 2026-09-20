package ForgeOps::Tracker::MetricBuffer;

use strict;
use warnings;
use threads;
use threads::shared;
use JSON::PP ();
use Scalar::Util qw(weaken);

# Collects individual capture_metric()/capture_infrastructure_metric() calls in-process and
# periodically flushes them as one batch, rather than one network call per capture. Unlike
# PerformanceFlusher this keeps a *list* of individually meaningful entries instead of summing them
# into buckets: a customer's own signup or payment is exactly the kind of thing they will want a
# genuinely accurate count/sum of later, so the server stores one row per entry as-is. Ported from
# gems/forge_ops_tracker's metric_buffer.rb and infrastructure_metric_buffer.rb, which are the same
# class twice; here it is one class instantiated twice, told which client method and interval to use.
#
# Three deliberate differences from the Ruby buffers:
#
# - A flush snapshots the first N entries and, on success, removes exactly those N, instead of
#   resetting the whole list, so an entry recorded while the request is in flight (the lock is not
#   held around the network call) is kept for the next flush rather than lost.
# - The buffer is capped at MAX_ENTRIES, and once full further entries are dropped until a flush
#   succeeds: a plan without the feature answers 403 on every flush, and an uncapped buffer would then
#   grow for as long as the process lives. Dropping the newest rather than the oldest keeps the
#   entries a flush is delivering at the front of the list, which is what makes removing exactly those
#   afterward exact.
# - A NaN or infinite value is dropped at record time: JSON::PP would encode it as the invalid JSON
#   token NaN/Inf and the server would reject the whole batch.
#
# Perl's ithreads share nothing by default (see PerformanceFlusher's own comment), so the entries live
# in a threads::shared array of JSON strings: a flat shared array sidesteps sharing nested structures.
# The background thread is started lazily on the first record, like DeliveryQueue's. An END block
# flushes whatever is left when the program ends normally, which is what a short-lived cron script that
# captures a few readings and falls off the end relies on.
use constant MAX_ENTRIES => 1000;

my @live_buffers;

sub new {
    my ($class, $configuration, $deliver, $interval) = @_;

    my @entries :shared;
    my $lock = 1;
    share($lock);

    my $self = bless {
        configuration => $configuration,
        deliver       => $deliver,     # takes an arrayref of hashrefs, returns whether it succeeded
        interval      => $interval,    # returns the flush interval in seconds
        entries       => \@entries,
        lock          => \$lock,
        worker        => undef,
    }, $class;

    push @live_buffers, $self;
    weaken($live_buffers[-1]);
    return $self;
}

# Adds one entry (everything but recorded_at, which is stamped here); returns whether it was kept.
sub record {
    my ($self, $entry) = @_;
    my $value = $entry->{value};
    unless (defined $value && !ref($value) && $value =~ /\A-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?\z/) {
        $self->{configuration}->log('[forge-ops-tracker] dropped a metric with a non-numeric or non-finite value');
        return 0;
    }

    $self->_ensure_worker;

    my $stamped = { %$entry, recorded_at => _now(), value => $value + 0 };
    lock(${ $self->{lock} });
    if (@{ $self->{entries} } >= MAX_ENTRIES) {
        $self->{configuration}->log('[forge-ops-tracker] metric buffer full, dropping a metric');
        return 0;
    }
    push @{ $self->{entries} }, JSON::PP::encode_json($stamped);
    return 1;
}

# Delivers everything buffered so far as one batch. A failed delivery keeps every entry.
sub flush {
    my ($self) = @_;

    my @snapshot;
    {
        lock(${ $self->{lock} });
        return unless @{ $self->{entries} };
        @snapshot = @{ $self->{entries} };
    }

    my $delivered = $self->{deliver}->([ map { JSON::PP::decode_json($_) } @snapshot ]);
    return unless $delivered;

    lock(${ $self->{lock} });
    # Exactly the entries just delivered: anything recorded while the request was in flight sits after
    # them and stays for the next flush.
    # shift in a loop: splice is not implemented for shared arrays.
    shift @{ $self->{entries} } for 1 .. @snapshot;
}

sub count {
    my ($self) = @_;
    lock(${ $self->{lock} });
    return scalar @{ $self->{entries} };
}

# Test-only: drops whatever is buffered without delivering it.
sub _clear {
    my ($self) = @_;
    lock(${ $self->{lock} });
    @{ $self->{entries} } = ();
}

sub _ensure_worker {
    my ($self) = @_;
    return if $self->{worker};

    my $buffer = $self;
    $self->{worker} = threads->create(sub {
        while (1) {
            my $interval = $buffer->{interval}->();
            $interval = 60 unless $interval && $interval > 0;
            sleep($interval);

            # Per tick, not left to kill the loop: one bad flush must not stop every flush after it.
            eval { $buffer->flush };
            if ($@) {
                eval { $buffer->{configuration}->log("[forge-ops-tracker] metric flush error: $@") };
            }
        }
    });
    $self->{worker}->detach;
}

sub _now {
    my @t = gmtime;
    return sprintf('%04d-%02d-%02dT%02d:%02d:%02dZ', $t[5] + 1900, $t[4] + 1, @t[3, 2, 1, 0]);
}

# A normal program end: deliver whatever is still buffered (in the main thread only: a detached worker
# also runs END blocks in some Perl builds, and must not flush twice).
END {
    if (threads->tid == 0) {
        for my $buffer (grep { defined } @live_buffers) {
            eval { $buffer->flush };
        }
    }
}

1;
