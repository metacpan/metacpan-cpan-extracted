use v5.36;
use Test2::V0;
use Time::HiRes qw(sleep);

use Linux::Event::Proactor;

subtest 'after expires successfully' => sub {
    my $loop = Linux::Event::Proactor->new;
    my @calls;

    my $op = $loop->after(
        0.02,
        data  => 'ctx',
        on_complete => sub ($op, $result, $data) {
            push @calls, [$op->state, $op->success, $result, $data];
        },
    );

    ok($op->is_pending, 'starts pending');

    is($loop->run_once, 0, 'no progress before expiry');

    sleep 0.03;

    my $n = $loop->run_once;
    ok($n >= 1, 'progress after expiry');

    ok($op->is_done, 'done after expiry');
    ok($op->success, 'success after expiry');
    is($op->result, { expired => 1 }, 'timer result stored');

    is(scalar(@calls), 1, 'callback ran once');
    is($calls[0][0], 'done', 'callback saw done');
    is($calls[0][1], 1, 'callback saw success');
    is($calls[0][2], { expired => 1 }, 'callback got result');
    is($calls[0][3], 'ctx', 'callback got data');
};

subtest 'cancelled after does not later expire' => sub {
    my $loop = Linux::Event::Proactor->new;
    my @calls;

    my $op = $loop->after(
        0.05,
        on_complete => sub ($op, $result, $data) {
            push @calls, $op->state;
        },
    );

    ok($op->cancel, 'cancel accepted');
    is($loop->run_once, 1, 'cancel callback dispatched');

    sleep 0.06;
    is($loop->run_once, 0, 'no later expiry progress');

    is(\@calls, ['cancelled'], 'only cancelled delivered');
};

done_testing;
