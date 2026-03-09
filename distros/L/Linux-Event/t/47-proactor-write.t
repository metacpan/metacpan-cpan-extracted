use v5.36;
use Test2::V0;

use Linux::Event::Proactor;

open my $fh, '>', \my $sink or die "failed to open scalar fh: $!";

subtest 'write success settles with expected result shape' => sub {
    my $loop = Linux::Event::Proactor->new;
    my @calls;

    my $op = $loop->write(
        fh   => $fh,
        buf  => 'abcdef',
        data => 'ctx',
        on_complete => sub ($op, $result, $data) {
            push @calls, [$op->state, $op->success, $op->failed, $result, $data];
        },
    );

    ok($op->is_pending, 'write starts pending');

    my $token = $op->_backend_token;
    $loop->_fake_complete_write_success($token, 6);

    ok($op->is_done, 'write is done');
    ok($op->success, 'write success true');
    ok(!$op->failed, 'write failed false');
    is(
        $op->result,
        {
            bytes => 6,
        },
        'write result stored',
    );

    is(scalar(@calls), 0, 'callback still deferred');
    is($loop->run_once, 1, 'callback dispatched');

    is(scalar(@calls), 1, 'callback ran once');
    is($calls[0][0], 'done', 'callback saw done');
    is($calls[0][1], 1, 'callback saw success');
    is($calls[0][2], 0, 'callback saw failed false');
    is(
        $calls[0][3],
        {
            bytes => 6,
        },
        'callback got expected result',
    );
    is($calls[0][4], 'ctx', 'callback got data');

    ok(!exists $loop->{ops_by_token}{$token}, 'op registry entry removed');
};

subtest 'write partial success is still success' => sub {
    my $loop = Linux::Event::Proactor->new;

    my $op = $loop->write(
        fh  => $fh,
        buf => 'abcdef',
    );

    my $token = $op->_backend_token;
    $loop->_fake_complete_write_success($token, 3);

    ok($op->is_done, 'done');
    ok($op->success, 'success');
    ok(!$op->failed, 'not failed');
    is(
        $op->result,
       {
           bytes => 3,
       },
       'partial write result shape is correct',
    );
};

subtest 'write error settles with Linux::Event::Error' => sub {
    my $loop = Linux::Event::Proactor->new;
    my @calls;

    my $op = $loop->write(
        fh   => $fh,
        buf  => 'abcdef',
        data => 'ctx',
        on_complete => sub ($op, $result, $data) {
            push @calls, [$op->state, $op->success, $op->failed, $result, $op->error, $data];
        },
    );

    my $token = $op->_backend_token;
    $loop->_fake_complete_write_error(
        $token,
        code    => 32,
        name    => 'EPIPE',
        message => 'Broken pipe',
    );

    ok($op->is_done, 'done');
    ok(!$op->success, 'success false');
    ok($op->failed, 'failed true');
    is($op->result, undef, 'no result on error');
    isa_ok($op->error, ['Linux::Event::Error'], 'error object stored');

    is(scalar(@calls), 0, 'callback still deferred');
    is($loop->run_once, 1, 'callback dispatched');

    is(scalar(@calls), 1, 'callback ran once');
    is($calls[0][0], 'done', 'callback saw done');
    is($calls[0][1], 0, 'callback saw success false');
    is($calls[0][2], 1, 'callback saw failed true');
    is($calls[0][3], undef, 'callback got undef result');
    isa_ok($calls[0][4], ['Linux::Event::Error'], 'callback can inspect error object');
    is($calls[0][5], 'ctx', 'callback got data');
};

subtest 'write cancel settles cancelled' => sub {
    my $loop = Linux::Event::Proactor->new;

    my $op = $loop->write(
        fh  => $fh,
        buf => 'abcdef',
    );

    ok($op->cancel, 'cancel accepted');
    ok($op->is_cancelled, 'op is cancelled');
};

done_testing;
