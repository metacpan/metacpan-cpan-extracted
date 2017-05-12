use strict;
use warnings;
use Test::More;
use Forks::Queue;
use Time::HiRes 'time';
require "t/exercises.tt";

for my $impl (IMPL()) {
    my $q1 = Forks::Queue->new( impl => $impl, style => 'fifo' );
    my $q2 = Forks::Queue->new( impl => $impl, style => 'fifo' );

    my $pid = fork();
    if ($pid == 0) {
        my $t2 = $q2->get;

        # (3) pause, add to q1
        uninterruptable_sleep(3);
        $q1->put(1..5);
        # q1: [1,2,3,4,5]  q2: []

        $t2 = $q2->get;
        # (7) pause
        # q1: []
        uninterruptable_sleep(3);

        # (9) add to q1
        $q1->put(6..10);
        # q1: [6,7,8,9,10]
        
        uninterruptable_sleep(3);
        $q1->put(11..15);
        # q1: [8,9,10,11,12,13,14,15]
        uninterruptable_sleep(3);
        $q1->put(16..20);        
        exit;
    }

    # (1) tell child to "start"
    $q2->put("start");
    # q1: []

    # (2) timed read from empty queue
    ok($q1->pending == 0, 'get_timed: short timeout on empty queue');
    my $ts0 = Time::HiRes::time;
    my @t = $q1->get_timed(1.0, 3);
    ok(@t == 0, 'get_timed(1) did not retrieve anything');
    my $ts1 = Time::HiRes::time;
    ok($ts1-$ts0 >= 1, 'get_timed waited >=1s');
    ok($ts1-$ts0 < 2.5,  'get_timed waited ~1s') or diag "elapsed=",$ts1-$ts0;

    # (4) timed read from non-empty queue
    ok($q1->pending == 0, 'get_timed with long timeout on empty queue');
    $ts0 = Time::HiRes::time;
    my $t = $q1->get_timed(4.0);
    $ts1 = Time::HiRes::time;
    is($t,1, 'get_timed  got first item off queue');
    ok($ts1-$ts0 < 4, 'get_timed did not time out') or do {
        diag "get_timed call ran ",$ts1-$ts0,"sec, queue contains:";
        $q1->_DUMP;
    };
    # q1: [2,3,4,5]

    # (5) timed large read from small queue
    ok($q1->pending > 0 && $q1->pending < 10,
       'large timed read from small queue');
    $ts0 = Time::HiRes::time;
    @t = $q1->dequeue_timed(4.0,10);
    $ts1 = Time::HiRes::time;
    is_deeply(\@t, [2,3,4,5], 'timed: got remaining 4 items off queue');
    ok($ts1-$ts0 >= 4, 'get_timed waited >= 4s') or diag $ts1-$ts0;
    ok($q1->pending == 0, 'timed: queue emptied');
    ok($q2->pending == 0, 'timed: sync queue empty');
    # q1: []

    # (6) tell child to start again
    $q2->put("start again");
    # q1: []

    # (8) read from q1
    ok($q1->pending == 0, 'long get_timed read from empty queue');
    $ts0 = Time::HiRes::time;
    @t = $q1->dequeue_timed(6.0,2);

    # (10) return from dequeue_timed call
    # q1: [8,9,10]
    $ts1 = Time::HiRes::time;
    is_deeply(\@t, [6,7], 'timed: got two items from queue');
    ok($ts1-$ts0 >= 3 && $ts1-$ts0 < 5.05, 'timed: ... in about 3 seconds')
        or diag $ts1-$ts0,"sec";
    ok($q1->pending > 0, 'queue not emptied');

    # (11) make large request from q1 
    # q1: [8,9,10]
    $ts0 = Time::HiRes::time;
    @t = $q1->dequeue_timed(5.0,5);

    # (13) return from dequeue_timed call
    # q1: [13,14,15]
    $ts1 = Time::HiRes::time;
    is_deeply(\@t, [8,9,10,11,12], 'timed: got five items from queue');
    ok($ts1-$ts0>1.99 && $ts1-$ts0 <4.5, 'timed: ... after about 3 seconds')
        or diag $ts1-$ts0,"sec";
    ok($q1->pending == 3, 'timed: 3 items remain');
}

done_testing();
