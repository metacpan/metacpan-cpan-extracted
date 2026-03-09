use v5.36;
use Test2::V0;
use Time::HiRes qw(sleep);

use Linux::Event::Proactor;

subtest 'at with future monotonic deadline expires' => sub {
    my $loop = Linux::Event::Proactor->new;
    my @calls;

    my $deadline = $loop->clock->now_s + 0.02;

    my $op = $loop->at(
        $deadline,
        data  => 'ctx',
        on_complete => sub ($op, $result, $data) {
            push @calls, [$op->state, $op->success, $result, $data];
        },
    );

    ok($op->is_pending, 'starts pending');

    sleep 0.03;
    my $n = $loop->run_once;

    ok($n >= 1, 'progress after deadline');
    ok($op->is_done, 'done');
    ok($op->success, 'success');
    is($op->result, { expired => 1 }, 'timer result stored');

    is(scalar(@calls), 1, 'callback ran once');
    is($calls[0][0], 'done', 'callback saw done');
    is($calls[0][1], 1, 'callback saw success');
    is($calls[0][2], { expired => 1 }, 'callback got result');
    is($calls[0][3], 'ctx', 'callback got data');
};

subtest 'at with past deadline completes asynchronously' => sub {
    my $loop = Linux::Event::Proactor->new;
    my @calls;

    my $deadline = $loop->clock->now_s - 1;

    my $op = $loop->at(
        $deadline,
        on_complete => sub ($op, $result, $data) {
            push @calls, $op->state;
        },
    );

    ok($op->is_pending, 'still starts pending');
    is(scalar(@calls), 0, 'no inline callback');

    my $n = $loop->run_once;

    ok($n >= 1, 'progress on run_once');
    ok($op->is_done, 'done after dispatch turn');
    is(\@calls, ['done'], 'callback fired once');
};

done_testing;
