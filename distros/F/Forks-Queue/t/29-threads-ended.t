use strict;
use warnings;
use Test::More;
use lib '.';   # 5.26 compat

# t/09_ended.t from Thread::Queue, but using threads and Forks::Queue

BEGIN {
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

require "t/tq-compatibility.tt";

my $num_threads = 3;
my $cycles = 2;
my $count = 2;

while (my $impl = tq::IMPL()) {

    # Test for end() while threads are blocked and no more items in queue
    {
        my @items = 1..($num_threads*$cycles*$count);
        my $q = Forks::Queue->new(impl => $impl, list => \@items);
        my $r = Forks::Queue->new(impl => $impl);

        my @threads;
        for my $ii (1..$num_threads) {
            push @threads, threads->create( sub {
                # Thread will loop until no more work is coming
              LOOP:
                while (my @set = $q->dequeue($count)) {
                    foreach my $item (@set) {
                        last LOOP if (! defined($item));
                        pass("'$item' read from queue in thread $ii");
                    }
                    select(undef, undef, undef, rand(1));
                    $r->enqueue($ii);
                }
                pass("Thread $ii exiting");
                                            });
        }

        # Make sure there's nothing in the queue and threads are blocking
        for my $ii (1..($num_threads*$cycles)) {
            $r->dequeue();
        }
        sleep(1);
        threads->yield();

        is($q->pending(), 0, 'Queue is empty');

        # Signal no more work is coming
        $q->end();

        is($q->pending(), undef, 'Queue is ended');

        for my $thread (@threads) {
            $thread->join;
            pass($thread->tid." joined");
        }
    }

    # Test for end() while threads are blocked and items still remain in queue
    if (1) {
        my @items = 1..($num_threads*$cycles*$count + 1);    #   12 + 1
        my $q = Forks::Queue->new(impl => $impl, list => \@items);
        my $r = Forks::Queue->new(impl => $impl);

        my @threads;
        for my $ii (1..$num_threads) {
            push @threads, threads->create( sub {
                # Thread will loop until no more work is coming
              LOOP:
                while (my @set = $q->dequeue($count)) {
                    foreach my $item (@set) {
                        last LOOP if (! defined($item));
                        pass("'$item' read from queue in thread $ii");
                    }
                    select(undef, undef, undef, rand(1));
                    $r->enqueue($ii);
                }
                pass("Thread $ii exiting");
                                            });
        }

        # Make sure there's nothing in the queue and threads are blocking
        for my $ii (1..($num_threads*$cycles)) {
            $r->dequeue();
        }
        sleep(1);
        threads->yield();

        is($q->pending(), 1, 'Queue has one left');
        # Signal no more work is coming
        $q->end();

        for my $thread (@threads) {
            $thread->join;
            pass($thread->tid." joined");
        }

        is($q->pending(), undef, 'Queue is ended');
    }

    # Test of end() send while items in queue
    {
        my @items = 1..($num_threads*$cycles*$count + 1);
        my $q = Forks::Queue->new(impl => $impl, list => \@items);

        my @threads;
        for my $ii (1..$num_threads) {
            push @threads, threads->create( sub {
                # Thread will loop until no more work is coming
              LOOP:
                while (my @set = $q->dequeue($count)) {
                    foreach my $item (@set) {
                        last LOOP if (! defined($item));
                        pass("'$item' read from queue in thread $ii");
                    }
                    select(undef, undef, undef, rand(1));
                }
                pass("Thread $ii exiting");
                                            });
        }

        # Signal no more work is coming to the blocked threads, they
        # should unblock.
        $q->end();

        for my $thread (@threads) {
            $thread->join;
            pass($thread->tid." joined");
        }
    }
}

done_testing();

# EOF
