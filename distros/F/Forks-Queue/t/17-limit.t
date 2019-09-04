use strict;
use warnings;
use Test::More;
use Forks::Queue;
use Time::HiRes;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

for my $impl (IMPL()) {
    my $q = Forks::Queue->new( impl => $impl, limit => 10,
                               on_limit => 'fail' );

    ok($q->limit == 10, "limit set in $impl constructor");
    ok($q->{on_limit} eq 'fail', 'on_limit set in constructor');

    my $c = $q->put(1..20);
    ok($c == 10, 'limit respected');

    $q->clear;
    ok($q->pending == 0, 'clear respected');


    $q->limit(5,'block');
    ok($q->limit == 5, 'limit set in 2-arg limit call');
    ok($q->{on_limit} eq 'block', 'on_limit set in 2-arg limit call');
    my $pid = fork();
    if ($pid == 0) {
        for (1..6) {
            my $i = $q->get;
            uninterruptable_sleep(0.5);
        }
        exit;
    }
    my $t0 = Time::HiRes::time;
    $c = $q->put(1..10);
    my $t1 = Time::HiRes::time - $t0;
    ok($c == 10, 'large put successful');
    ok($t1 >= 1.75, 'large put took some time') or diag "${t1} sec";
    waitpid $pid,0;

    ok($q->pending == 4, 'queue partially consumed in child');
    $q->clear;
    ok($q->pending == 0, 'clear respected');


    $q->limit(12, 'fail');
    ok($q->limit == 12, 'limit reset in 2-arg call');
    ok($q->{on_limit} eq 'fail', 'on_limit reset in 2-arg call');

    $c = $q->put(1..15);
    ok($c == 12, 'limit respected');
    ok($q->pending == 12, 'limit respected');
    $q->clear;
    ok($q->pending == 0, 'clear respected');

    # $queue->limit as an lvalue may not work in Perl <v5.14
    if (!tied($q->limit)) {
        diag "\$q->limit as an lvalue will not work for impl=$impl, v$]";
    } else {
        $q->limit = 6;
        is($q->{limit}, 6, "limit lvalue in $impl");
        $c = $q->put(1..40);
        is($c, 6, 'limit from lvalue respected') or diag $c;
    }

    $q->clear;
    ok($q->pending == 0, 'queue cleared');

    $q->limit(10);
    ok($q->limit == 10, 'limit updated in parent');

    $pid = fork();
    if ($pid == 0) {
        $q->limit(5);
        exit;
    }
    waitpid $pid,0;
    sleep 1;
    ok($q->limit == 5, 'limit updated in child') or diag $q->limit;

    $pid = fork();
    if ($pid == 0) {
        if (tied($q->limit)) {
            $q->limit = 17;
        } else {
            $q->limit(17);
        }
        $q->put(5);
        exit;
    }
    waitpid $pid,0;
    sleep 1;
    is($q->limit, 17, 'limit updated in child with lvalue')
        or diag $q->limit;
}

done_testing();
