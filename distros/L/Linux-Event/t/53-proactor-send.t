use v5.36;
use Test2::V0;

use Socket qw(AF_UNIX SOCK_STREAM);
use Linux::Event::Proactor;

socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, 0)
    or die "socketpair failed: $!";

subtest 'send success settles with expected result shape' => sub {
    my $loop = Linux::Event::Proactor->new;
    my @calls;

    my $op = $loop->send(
        fh   => $left,
        buf  => 'abcdef',
        data => 'ctx',
        on_complete => sub ($op, $result, $data) {
            push @calls, [$op->state, $op->success, $op->failed, $result, $data];
        },
    );

    ok($op->is_pending, 'send starts pending');

    my $token = $op->_backend_token;
    $loop->_fake_complete_send_success($token, 6);

    ok($op->is_done, 'send is done');
    ok($op->success, 'send success true');
    ok(!$op->failed, 'send failed false');
    is($op->result, { bytes => 6 }, 'send result stored');

    is(scalar(@calls), 0, 'callback still deferred');
    is($loop->run_once, 1, 'callback dispatched');
    is(scalar(@calls), 1, 'callback ran once');
    is($calls[0][3], { bytes => 6 }, 'callback got expected result');
    is($calls[0][4], 'ctx', 'callback got data');
};

subtest 'send partial success is still success' => sub {
    my $loop = Linux::Event::Proactor->new;
    my $op = $loop->send(fh => $left, buf => 'abcdef');
    my $token = $op->_backend_token;
    $loop->_fake_complete_send_success($token, 3);
    ok($op->is_done, 'done');
    ok($op->success, 'success');
    ok(!$op->failed, 'not failed');
    is($op->result, { bytes => 3 }, 'partial send result shape is correct');
};

subtest 'send error settles with Linux::Event::Error' => sub {
    my $loop = Linux::Event::Proactor->new;
    my @calls;

    my $op = $loop->send(
        fh   => $left,
        buf  => 'abcdef',
        data => 'ctx',
        on_complete => sub ($op, $result, $data) {
            push @calls, [$op->state, $op->success, $op->failed, $result, $op->error, $data];
        },
    );

    my $token = $op->_backend_token;
    $loop->_fake_complete_send_error(
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
    isa_ok($calls[0][4], ['Linux::Event::Error'], 'callback can inspect error object');
    is($calls[0][5], 'ctx', 'callback got data');
};

subtest 'send cancel settles cancelled' => sub {
    my $loop = Linux::Event::Proactor->new;
    my $op = $loop->send(fh => $left, buf => 'abcdef');
    ok($op->cancel, 'cancel accepted');
    ok($op->is_cancelled, 'op is cancelled');
};

done_testing;
