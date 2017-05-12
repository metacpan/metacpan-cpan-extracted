use strict;
use warnings;
use Test::More;
use Forks::Queue;
use Time::HiRes;
require "t/exercises.tt";

# t/04_errs.t from Thread::Queue, but using threads and Forks::Queue
# this test does not actually require threads

use Test::More;

foreach my $impl (IMPL()) {
    my $q = Forks::Queue->new(list => [1..10], impl => $impl);
    ok($q, 'New queue');

    eval { $q->dequeue(undef); };
    like($@, qr/Invalid 'count'/, $@);
    eval { $q->dequeue(0); };
    like($@, qr/Invalid 'count'/, $@);
    eval { $q->dequeue(0.5); };
    like($@, qr/Invalid 'count'/, $@);
    eval { $q->dequeue(-1); };
    like($@, qr/Invalid 'count'/, $@);
    eval { $q->dequeue('foo'); };
    like($@, qr/Invalid 'count'/, $@);

    eval { $q->dequeue_nb(undef); };
    like($@, qr/Invalid 'count'/, $@);
    eval { $q->dequeue_nb(0); };
    like($@, qr/Invalid 'count'/, $@);
    eval { $q->dequeue_nb(-0.5); };
    like($@, qr/Invalid 'count'/, $@);
    eval { $q->dequeue_nb(-1); };
    like($@, qr/Invalid 'count'/, $@);
    eval { $q->dequeue_nb('foo'); };
    like($@, qr/Invalid 'count'/, $@);

    eval { $q->peek(undef); };
    like($@, qr/Invalid 'index'/, $@);
    eval { $q->peek(3.3); };
    like($@, qr/Invalid 'index'/, $@);
    eval { $q->peek('foo'); };
    like($@, qr/Invalid 'index'/, $@);

    eval { $q->insert(); };
    like($@, qr/Invalid 'index'/, $@);
    eval { $q->insert(undef); };
    like($@, qr/Invalid 'index'/, $@);
    eval { $q->insert(.22); };
    like($@, qr/Invalid 'index'/, $@);
    eval { $q->insert('foo'); };
    like($@, qr/Invalid 'index'/, $@);

    eval { $q->extract(undef); };
    like($@, qr/Invalid 'index'/, $@);
    eval { $q->extract('foo'); };
    like($@, qr/Invalid 'index'/, $@);
    eval { $q->extract(1.1); };
    like($@, qr/Invalid 'index'/, $@);
    eval { $q->extract(0, undef); };
    like($@, qr/Invalid 'count'/, $@);
    eval { $q->extract(0, 0); };
    like($@, qr/Invalid 'count'/, $@);
    eval { $q->extract(0, 3.3); };
    like($@, qr/Invalid 'count'/, $@);
    eval { $q->extract(0, -1); };
    like($@, qr/Invalid 'count'/, $@);
    eval { $q->extract(0, 'foo'); };
    like($@, qr/Invalid 'count'/, $@);
}

done_testing();

# EOF
