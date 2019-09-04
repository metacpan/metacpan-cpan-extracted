#use strict;
#use warnings;
#use Test::More;
#use Forks::Queue;
#use Time::HiRes;
#require "t/exercises.tt";
use lib '.';   # 5.26 compat

# t/10_timed.t from Thread::Queue, but using threads and Forks::Queue

BEGIN {
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

require "t/tq-compatibility.tt";

while (my $impl = tq::IMPL()) {

    ### ->dequeue_timed(TIMEOUT, COUNT) test ###
    
    my $q = Forks::Queue->new(impl => $impl);
    ok($q, 'New queue');

    my @items = qw/foo bar baz qux exit/;
    $q->enqueue(@items);
    is($q->pending(), scalar(@items), 'Queue count');

    threads->create(sub {
        is($q->pending(), scalar(@items), 'Queue count in thread');
        while (my @el = $q->dequeue_timed(2.5, 2)) {
            is($el[0], shift(@items), "Thread got $el[0]");
            if ($el[0] eq 'exit') {
                is(scalar(@el), 1, 'Thread to exit');
            } else {
                is($el[1], shift(@items), "Thread got $el[1]");
            }
        }
        is($q->pending(), 0, 'Empty queue');
        $q->enqueue('done');
                    })->join();

    is($q->pending(), 1, 'Queue count after thread');
    is($q->dequeue(), 'done', 'Thread reported done');
    is($q->pending(), 0, 'Empty queue');

    ### ->dequeue_timed(TIMEOUT) test on empty queue ###

    threads->create(sub {
        is($q->pending(), 0, 'Empty queue in thread');
        my @el = $q->dequeue_timed(1.5);
        is($el[0], undef, "Thread got no items");
        is($q->pending(), 0, 'Empty queue in thread');
        $q->enqueue('done');
                    })->join();
    
    is($q->pending(), 1, 'Queue count after thread');
    is($q->dequeue(), 'done', 'Thread reported done');
    is($q->pending(), 0, 'Empty queue');
}

done_testing();

# EOF
