package ForgeOps::Tracker::DeliveryQueue;

use strict;
use warnings;
use threads;
use Thread::Queue;

# A small bounded queue drained by a background thread, so delivery never blocks the caller that
# raised the error. Uses Perl's own ithreads + Thread::Queue: the closest real equivalent to the
# Ruby/Java clients' own background-thread DeliveryQueue (see
# gems/forge_ops_tracker/lib/forge_ops_tracker/delivery_queue.rb), and, unlike a manual
# fork()-per-event approach, Thread::Queue is purpose-built by the Perl core itself as a
# thread-safe hand-off between a producer and a consumer thread, so no separate locking is needed
# here.
#
# The worker thread is started lazily, on first push, not at construction time: the same
# fork-safety reasoning the Ruby/Python clients' own DeliveryQueue documents for themselves: a
# prefork Perl app server (Starman running in prefork mode, or mod_perl2's own prefork MPM) forks
# worker processes *after* the application (and this module) has already loaded, so a thread
# started eagerly at load time would simply not exist in a forked child; starting fresh on first
# push means each forked worker gets its own live thread regardless of when it was forked relative
# to when the module loaded.
#
# `queue_size` bounds pending items via Thread::Queue's own `pending` count, checked before every
# enqueue: Thread::Queue has no native "drop instead of block when full" mode, so that behavior
# is implemented explicitly here to match every other SDK's own bounded-queue contract.
sub new {
    my ($class, $configuration, $client) = @_;
    return bless {
        configuration => $configuration,
        client        => $client,
        queue         => Thread::Queue->new,
        worker        => undef,
    }, $class;
}

sub push {
    my ($self, $payload) = @_;
    my $max_size = $self->{configuration}{queue_size} > 0 ? $self->{configuration}{queue_size} : 1;

    if ($self->{queue}->pending >= $max_size) {
        $self->{configuration}->log('[forge-ops-tracker] delivery queue full, dropping event');
        return 0;
    }

    $self->{queue}->enqueue($payload);
    $self->_ensure_worker;
    return 1;
}

sub _ensure_worker {
    my ($self) = @_;
    return if $self->{worker};

    my $queue = $self->{queue};
    my $client = $self->{client};
    my $configuration = $self->{configuration};

    $self->{worker} = threads->create(sub {
        while (defined(my $payload = $queue->dequeue)) {
            # Per-item, not wrapping the whole loop: one bad delivery must not stop every event
            # queued after it. Also guards against a logger callback that didn't clone cleanly
            # into this thread (a known ithreads sharp edge for CODE ref-holding objects):
            # dropping the log message in that unlikely case is still strictly better than this
            # worker thread dying and silently stopping all future deliveries.
            eval { $client->deliver($payload) };
            if ($@) {
                eval { $configuration->log("[forge-ops-tracker] delivery worker error: $@") };
            }
        }
    });
    $self->{worker}->detach;
}

1;
