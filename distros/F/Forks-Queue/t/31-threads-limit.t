use strict;
use warnings;
use Test::More;
use Forks::Queue;
use Time::HiRes;
use lib '.';
require "t/exercises.tt";

# t/11_limit.t from Thread::Queue, but using threads and Forks::Queue
# queue limits are implemented differently in Forks::Queue, so this
# test script will not pass against Forks::Queue
#
# if a queue is under capacity but the current input to enqueue() would
# put it over capacity:
#     Thread::Queue will add the items
#     Forks::Queue, on_limit = 'fail', will add items up to capacity,
#         and then issue a warning
#     Forks::Queue, on_limit = 'block', will add items up to capacity,
#         and then block until other queue accessors make capacity available
#

BEGIN {
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

#use threads;
use Test::More;
require "t/tq-compatibility.tt";

$Forks::Queue::OPTS{dflock} = 1;

while (my $impl = tq::IMPL()) {

    my $q = Forks::Queue->new(impl => $impl, on_limit => 'tq-compat');
    my $rpt = Forks::Queue->new(impl => $impl);

    my $th = threads->create( sub {
        # (1) Set queue limit, and report it
        if ($] < 5.014) { $q->limit(3); } else { $q->limit = 3 }
        $rpt->enqueue($q->limit);

        # (3) Fetch an item from queue
        my $item = $q->dequeue();
        is($item, 1, 'Dequeued item 1');
        # Report queue count
        $rpt->enqueue($q->pending());

        # q = (2, 3, 4, 5); r = (4)

        # (4) Enqueue more items - will block
        $q->enqueue(6, 7);
        # q = (5, 'foo', 6, 7); r = (4, 3, 4, 3)

        # (6) Get reports from main
        my @items = $rpt->dequeue(5);
        is_deeply(\@items, [4, 3, 4, 3, 'go'], 'Queue reports');
    });

    # (2) Read queue limit from thread
    my $item = $rpt->dequeue();
    is($item, $q->limit, 'Queue limit set');
    # Send items
    $q->enqueue(1, 2, 3, 4, 5);

    # (5) Read queue count
    $item = $rpt->dequeue;
    # q = (2, 3, 4, 5); r = ()
    is($item, $q->pending(), 'Queue count');
    # Report back the queue count
    $rpt->enqueue($q->pending);
    # q = (2, 3, 4, 5); r = (4)

    # Read an item from queue
    $item = $q->dequeue();
    is($item, 2, 'Dequeued item 2');
    # q = (3, 4, 5); r = (4)
    # Report back the queue count
    $rpt->enqueue($q->pending);
    # q = (3, 4, 5); r = (4, 3)

    # 'insert' doesn't care about queue limit
    my $zz = $q->insert(3, 'foo'); ok($zz, "insert successful");
    $rpt->enqueue($q->pending);
    # q = (3, 4, 5, 'foo'); r = (4, 3, 4)

    # Read an item from queue
    $item = $q->dequeue();
    is($item, 3, 'Dequeued item 3');
    # q = (4, 5, 'foo'); r = (4, 3, 4)
    # Report back the queue count
    $rpt->enqueue($q->pending);
    # q = (4, 5, 'foo'); r = (4, 3, 4, 3)

    # Read all items from queue
    my @items = $q->dequeue(3);
    is_deeply(\@items, [4, 5, 'foo'], 'Dequeued 3 items');
    # Thread is now unblocked

    @items = $q->dequeue(2);
    is_deeply(\@items, [6, 7], 'Dequeued 2 items');

    # Thread is now unblocked
    # Handshake with thread
    $rpt->enqueue('go');

    # (7) - Done
    {
        local $Carp::verbose = 0;
        $th->join;
    }

    # It's an error to call dequeue methods with COUNT > LIMIT
    {
        local $Carp::verbose = 0;
        eval { $q->dequeue(5); };
    }
    like($@, qr/exceeds queue size limit/, $@);

    # Bug #120157
    #  Fix deadlock from combination of dequeue_nb, enqueue and queue size limit

    # (1) Fill queue
    $q->enqueue(1..3);
    is($q->pending, 3, 'Queue loaded');

    # (2) Thread will block trying to add to full queue
    $th = threads->create( sub {
        $q->enqueue(99);
        return('OK');
    });
    threads->yield();

    # (3) Dequeue an item so that thread can unblock
    is($q->dequeue_nb(), 1, 'Dequeued item');

    # (4) Thread unblocks
    is($th->join(), 'OK', 'Thread exited');

    # (5) Fetch queue to show thread's item was enqueued
    @items = ();
    while (my $item = $q->dequeue_nb()) {
        push(@items, $item);
    }
    is_deeply(\@items, [2,3,99], 'Dequeued remaining');
}

done_testing;
exit(0);

# EOF
