package ForgeOps::Tracker::DeliveryQueue;

use strict;
use warnings;
use threads;
use threads::shared;
use Thread::Queue;
use Time::HiRes ();

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
#
# The worker is detached, and Perl kills detached threads when the program ends, so a plain script
# that reports an error and falls off the end used to lose it. The END block below drains every
# queue that has ever had something pushed onto it: it delivers whatever is still queued on the
# main thread, then waits for a delivery the worker already has under way, within DRAIN_TIMEOUT
# seconds in total. A program that never reports anything never waits. Same contract as the Ruby
# gem's DeliveryQueue#drain.
use constant DRAIN_TIMEOUT => 5;

my @live_queues;

sub new {
    my ($class, $configuration, $client) = @_;
    my $in_flight = 0;
    share($in_flight);
    return bless {
        configuration => $configuration,
        client        => $client,
        queue         => Thread::Queue->new,
        worker        => undef,
        in_flight     => \$in_flight,
        registered    => 0,
    }, $class;
}

sub push {
    my ($self, $payload) = @_;
    my $max_size = $self->{configuration}{queue_size} > 0 ? $self->{configuration}{queue_size} : 1;

    if ($self->{queue}->pending >= $max_size) {
        $self->{configuration}->log('[forge-ops-tracker] delivery queue full, dropping event');
        return 0;
    }

    {
        lock(${ $self->{in_flight} });
        $self->{queue}->enqueue($payload);
        cond_signal(${ $self->{in_flight} });
    }
    $self->_register_drain;
    $self->_ensure_worker;
    return 1;
}

# drain($timeout): delivers whatever is still queued on the calling thread, then waits for a
# delivery the worker thread already has under way, giving up after $timeout seconds (DRAIN_TIMEOUT
# by default). Returns 1 if everything went out in time, 0 otherwise. Never dies.
sub drain {
    my ($self, $timeout) = @_;
    $timeout = DRAIN_TIMEOUT unless defined $timeout;
    my $deadline = Time::HiRes::time() + $timeout;
    my $in_flight = $self->{in_flight};

    while (Time::HiRes::time() < $deadline) {
        my $payload = $self->{queue}->dequeue_nb;
        if (defined $payload) {
            eval { $self->{client}->deliver($payload) };
            if ($@) {
                eval { $self->{configuration}->log("[forge-ops-tracker] delivery error during drain: $@") };
            }
            next;
        }
        {
            lock(${$in_flight});
            return 1 if ${$in_flight} == 0 && !$self->{queue}->pending;
        }
        Time::HiRes::sleep(0.01);
    }

    lock(${$in_flight});
    return (${$in_flight} == 0 && !$self->{queue}->pending) ? 1 : 0;
}

# drain_all($timeout, @queues): drains @queues (by default every queue that has had something
# pushed onto it), sharing one $timeout between them. Used by ForgeOps::Tracker::flush and the END
# block below.
sub drain_all {
    my ($class, $timeout, @queues) = @_;
    @queues = @live_queues unless @queues;
    $timeout = DRAIN_TIMEOUT unless defined $timeout;
    my $deadline = Time::HiRes::time() + $timeout;
    my $all_sent = 1;

    for my $queue (grep { defined } @queues) {
        my $remaining = $deadline - Time::HiRes::time();
        $remaining = 0 if $remaining < 0;
        $all_sent = 0 unless $queue->drain($remaining);
    }
    return $all_sent;
}

# Registered on the first push, not at construction, so a program that never reports anything
# never waits at exit at all. A strong reference, not a weak one like MetricBuffer's: `exit` frees a
# script's own file-scoped lexicals before END blocks run, and a queue held only there would be gone
# by the time its items need sending.
sub _register_drain {
    my ($self) = @_;
    return if $self->{registered};
    $self->{registered} = 1;
    CORE::push(@live_queues, $self);
    return;
}

sub _ensure_worker {
    my ($self) = @_;
    return if $self->{worker};

    my $queue = $self->{queue};
    my $client = $self->{client};
    my $configuration = $self->{configuration};
    my $in_flight = $self->{in_flight};

    $self->{worker} = threads->create(sub {
        while (1) {
            # Taking an item off the queue and counting it as in flight happen under one lock, so
            # drain() never sees the queue empty and nothing in flight while this thread holds an
            # item it hasn't delivered yet. push() signals the same lock when it enqueues.
            my $payload;
            {
                lock(${$in_flight});
                $payload = $queue->dequeue_nb;
                if (defined $payload) {
                    ${$in_flight}++;
                } else {
                    cond_timedwait(${$in_flight}, time + 1);
                }
            }
            next unless defined $payload;

            # Per-item, not wrapping the whole loop: one bad delivery must not stop every event
            # queued after it. Also guards against a logger callback that didn't clone cleanly
            # into this thread (a known ithreads sharp edge for CODE ref-holding objects):
            # dropping the log message in that unlikely case is still strictly better than this
            # worker thread dying and silently stopping all future deliveries.
            eval { $client->deliver($payload) };
            if ($@) {
                eval { $configuration->log("[forge-ops-tracker] delivery worker error: $@") };
            }
            { lock(${$in_flight}); ${$in_flight}--; }
        }
    });
    $self->{worker}->detach;
}

# A normal program end: drain every queue that was used (in the main thread only: a detached worker
# also runs END blocks in some Perl builds, and must not deliver twice). Keeps the program's own
# exit status, which a delivery's HTTP call must not change.
END {
    if (threads->tid == 0 && @live_queues) {
        local $?;
        eval { __PACKAGE__->drain_all(DRAIN_TIMEOUT) };
    }
}

1;
