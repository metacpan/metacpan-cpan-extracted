use v5.36;
use Test2::V0;

use Linux::Event::Proactor;

my $loop = Linux::Event::Proactor->new;

subtest 'operation cancel settles asynchronously through queue machinery' => sub {
    my @calls;

    my $op = $loop->after(
        5,
        data  => 'ctx',
        on_complete => sub ($op, $result, $data) {
            push @calls, [$op->state, $result, $data];
        },
    );

    ok($op->is_pending, 'op starts pending');

    ok($op->cancel, 'cancel accepted');
    ok($op->is_cancelled, 'op now cancelled');
    is(\@calls, [], 'callback not run inline');

    $loop->run_once;

    is(scalar(@calls), 1, 'callback ran once after run_once');
    is($calls[0][0], 'cancelled', 'callback saw cancelled state');
    is($calls[0][1], undef, 'cancelled callback has undef result');
    is($calls[0][2], 'ctx', 'callback got data');
};

subtest 'detach suppresses callback' => sub {
    my $called = 0;

    my $op = $loop->after(
        5,
        on_complete => sub ($op, $result, $data) {
            $called++;
        },
    );

    $op->detach;
    ok($op->cancel, 'cancel accepted after detach');

    $loop->run_once;

    is($called, 0, 'callback suppressed');
    ok($op->is_cancelled, 'state still settled');
};

done_testing;
