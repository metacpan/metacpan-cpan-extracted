use strict;
use warnings;
use Test::More;

# t/03_peek.t from Thread::Queue, but using threads and Forks::Queue
# t/02_refs.t is not a suitable test for Forks::Queue.

BEGIN {
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

require "t/tq-compatibility.tt";

while (my $impl = tq::IMPL()) {
    my $q = Thread::Queue->new(1..10);
    ok($q && ref($q) =~ /Forks::Queue/, 'New queue');

    $q->enqueue([ qw/foo bar/ ]);

sub q_check
{
    is($q->peek(3), 4, 'Peek at queue');
    is($q->peek(-3), 9, 'Negative peek');

    my $nada = $q->peek(20);
    ok(! defined($nada), 'Big peek');
    $nada = $q->peek(-20);
    ok(! defined($nada), 'Big negative peek');

    my $ary = $q->peek(-1);
    is_deeply($ary, [ qw/foo bar/ ], 'Peek array');

    is($q->pending(), 11, 'Queue count in thread');
}

    threads->create(sub {
        q_check();
        threads->create('q_check')->join();
                    })->join();
    q_check();
}

done_testing();

# EOF
