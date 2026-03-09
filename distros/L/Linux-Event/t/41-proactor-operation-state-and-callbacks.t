use v5.36;
use Test2::V0;

use Linux::Event::Proactor;
use Linux::Event::Error;

subtest 'post-terminal on_complete is still async' => sub {
    my $loop = Linux::Event::Proactor->new;
    my @calls;

    my $op = $loop->after(5);
    ok($op->cancel, 'cancel accepted');
    ok($op->is_cancelled, 'op cancelled');
    is(\@calls, [], 'nothing ran yet');

    $op->on_complete(sub ($op, $result, $data) {
        push @calls, [$op->state, $result, $data];
    });

    is(\@calls, [], 'still not inline after on_complete on terminal op');

    $loop->run_once;

    is(scalar(@calls), 1, 'callback ran once');
    is($calls[0][0], 'cancelled', 'callback saw cancelled state');
    is($calls[0][1], undef, 'no result on cancelled op');
};

subtest 'second callback registration croaks' => sub {
    my $loop = Linux::Event::Proactor->new;

    my $op = $loop->after(
        5,
        on_complete => sub ($op, $result, $data) { },
    );

    like(
        dies { $op->on_complete(sub ($op, $result, $data) { }) },
        qr/callback already set/,
        'second callback rejected',
    );
};

subtest 'success settlement exposes result and success truth' => sub {
    my $loop = Linux::Event::Proactor->new;
    my @calls;

    my $op = $loop->_new_op(
        kind => 'timeout',
        data => 'ctx',
        on_complete => sub ($op, $result, $data) {
            push @calls, [$op->state, $op->success, $op->failed, $result, $data];
        },
    );

    $op->_settle_success({ expired => 1 });

    ok($op->is_done, 'done');
    ok(!$op->is_cancelled, 'not cancelled');
    ok($op->success, 'success true');
    ok(!$op->failed, 'failed false');
    is($op->result, { expired => 1 }, 'result stored');
    is($op->error, undef, 'no error');
    is(scalar(@calls), 0, 'callback still deferred');

    $loop->run_once;

    is(scalar(@calls), 1, 'callback ran once');
    is($calls[0][0], 'done', 'callback saw done');
    is($calls[0][1], 1, 'callback saw success');
    is($calls[0][2], 0, 'callback saw failed false');
    is($calls[0][3], { expired => 1 }, 'callback got result');
    is($calls[0][4], 'ctx', 'callback got data');
};

subtest 'error settlement exposes error and failure truth' => sub {
    my $loop = Linux::Event::Proactor->new;
    my @calls;

    my $op = $loop->_new_op(
        kind => 'read',
        data => 'ctx',
        on_complete => sub ($op, $result, $data) {
            push @calls, [$op->state, $op->success, $op->failed, $result, $op->error, $data];
        },
    );

    my $err = Linux::Event::Error->new(
        code    => 32,
        name    => 'EPIPE',
        message => 'Broken pipe',
    );

    $op->_settle_error($err);

    ok($op->is_done, 'done');
    ok(!$op->is_cancelled, 'not cancelled');
    ok(!$op->success, 'success false');
    ok($op->failed, 'failed true');
    is($op->result, undef, 'no result');
    is($op->error, $err, 'error stored');
    is(scalar(@calls), 0, 'callback still deferred');

    $loop->run_once;

    is(scalar(@calls), 1, 'callback ran once');
    is($calls[0][0], 'done', 'callback saw done');
    is($calls[0][1], 0, 'callback saw success false');
    is($calls[0][2], 1, 'callback saw failed true');
    is($calls[0][3], undef, 'callback got undef result');
    is($calls[0][4], $err, 'callback can inspect error on op');
    is($calls[0][5], 'ctx', 'callback got data');
};

subtest 'detach clears data and callback but preserves settled truth' => sub {
    my $loop = Linux::Event::Proactor->new;
    my $called = 0;

    my $op = $loop->after(
        5,
        data  => { x => 1 },
        on_complete => sub ($op, $result, $data) {
            $called++;
        },
    );

    $op->detach;

    is($op->data, undef, 'data cleared by detach');

    ok($op->cancel, 'cancel accepted');
    $loop->run_once;

    is($called, 0, 'callback suppressed');
    ok($op->is_cancelled, 'truth preserved');
    is($op->result, undef, 'no result');
    is($op->error, undef, 'no error');
};

subtest 'terminal settlement cannot happen twice' => sub {
    my $loop = Linux::Event::Proactor->new;
    my $op   = $loop->_new_op(kind => 'timeout');

    $op->_settle_success({ expired => 1 });

    like(
        dies { $op->_settle_cancelled },
        qr/already terminal/,
        'second settlement rejected',
    );
};

done_testing;
