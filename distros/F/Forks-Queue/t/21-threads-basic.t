use strict;
use warnings;
use Test::More;
use lib '.';   # 5.26 compat

# t/01_basic.t from Thread::Queue, but using threads and Forks::Queue

BEGIN {
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

require "t/tq-compatibility.tt";

### Basic usage with multiple threads ###

my $q;
my $count;

sub reader {
    my $id = threads->tid();
    while ((my $el = $q->dequeue()) != -1) {
        ok($el >= 1, "Thread $id got $el");
        select(undef, undef, undef, rand(1));
    }
    ok(1, "Thread $id done");
}

sub reader2 {
    my $id = threads->tid();
    while (1) {
        my @el = $q->dequeue($count);
        is(scalar(@el), $count, "Thread $id got @el");
        select(undef, undef, undef, rand(1));
        return if ($el[0] == 0);
    }
}



my $nthreads = 5;

while (my $impl = tq::IMPL()) {
    $q = Thread::Queue->new(1..$nthreads);
    ok($q && ref($q) =~ /Forks::Queue/, 'New queue');
    is($q->pending(), $nthreads, 'Pre-populated queue count');

    my @threads;
    push(@threads, threads->create('reader')) for (1..$nthreads);

    for (1..20) {
        select(undef, undef, undef, rand(1));
        $q->enqueue($_);
    }

    $q->enqueue((-1) x $nthreads);   # One end marker for each thread

    $_->join() foreach @threads;
    undef(@threads);

    is($q->pending(), 0, 'Empty queue');


    ### ->dequeue_nb() test ###

    $q = Forks::Queue->new( impl => $impl );
    ok($q, 'New queue');
    is($q->pending(), 0, 'Empty queue');

    my @items = qw/foo bar baz/;
    $q->enqueue(@items);

    threads->create(sub {
        is($q->pending(), scalar(@items), 'Queue count in thread');
        while (my $el = $q->dequeue_nb()) {
            is($el, shift(@items), "Thread got $el");
        }
        is($q->pending(), 0, 'Empty queue');
        $q->enqueue('done');
                    })->join();

    is($q->pending(), 1, 'Queue count after thread');
    is($q->dequeue(), 'done', 'Thread reported done');
    is($q->pending(), 0, 'Empty queue');

    
    ### ->dequeue(COUNT) test ###

    $count = 3;

    push(@threads, threads->create('reader2')) for (1..$nthreads);

    $q->enqueue(1..4*$count*$nthreads);
    $q->enqueue((0) x ($count*$nthreads));

    $_->join() foreach @threads;
    undef(@threads);

    is($q->pending(), 0, 'Empty queue');


    ### ->dequeue_nb(COUNT) test ###

    @items = qw/foo bar baz qux exit/;
    $q->enqueue(@items);
    is($q->pending(), scalar(@items), 'Queue count');

    threads->create(sub {
        is($q->pending(), scalar(@items), 'Queue count in thread');
        while (my @el = $q->dequeue_nb(2)) {
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
}

done_testing();

