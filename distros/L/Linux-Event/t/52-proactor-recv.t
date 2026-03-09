use v5.36;
use Test2::V0;

use Socket qw(AF_UNIX SOCK_STREAM);
use Linux::Event::Proactor;

socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, 0)
    or die "socketpair failed: $!";

subtest 'recv success settles with expected result shape' => sub {
    my $loop = Linux::Event::Proactor->new;
    my @calls;

    my $op = $loop->recv(
        fh   => $left,
        len  => 10,
        data => 'ctx',
        on_complete => sub ($op, $result, $data) {
            push @calls, [$op->state, $op->success, $op->failed, $result, $data];
        },
    );

    ok($op->is_pending, 'recv starts pending');

    my $token = $op->_backend_token;
    $loop->_fake_complete_recv_success($token, 'hello');

    ok($op->is_done, 'recv is done');
    ok($op->success, 'recv success true');
    ok(!$op->failed, 'recv failed false');
    is($op->result, { bytes => 5, data => 'hello', eof => 0 }, 'recv result stored');

    is(scalar(@calls), 0, 'callback still deferred');
    is($loop->run_once, 1, 'callback dispatched');
    is(scalar(@calls), 1, 'callback ran once');
    is($calls[0][3], { bytes => 5, data => 'hello', eof => 0 }, 'callback got expected result');
    is($calls[0][4], 'ctx', 'callback got data');
};

subtest 'recv eof is success with eof flag' => sub {
    my $loop = Linux::Event::Proactor->new;
    my $op = $loop->recv(fh => $left, len => 10);
    my $token = $op->_backend_token;
    $loop->_fake_complete_recv_success($token, '');
    ok($op->is_done, 'done');
    ok($op->success, 'success');
    is($op->result, { bytes => 0, data => '', eof => 1 }, 'eof result shape is correct');
};

subtest 'recv error settles with Linux::Event::Error' => sub {
    my $loop = Linux::Event::Proactor->new;
    my @calls;

    my $op = $loop->recv(
        fh   => $left,
        len  => 10,
        data => 'ctx',
        on_complete => sub ($op, $result, $data) {
            push @calls, [$op->state, $op->success, $op->failed, $result, $op->error, $data];
        },
    );

    my $token = $op->_backend_token;
    $loop->_fake_complete_recv_error(
        $token,
        code    => 104,
        name    => 'ECONNRESET',
        message => 'Connection reset by peer',
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

subtest 'recv cancel settles cancelled' => sub {
    my $loop = Linux::Event::Proactor->new;
    my $op = $loop->recv(fh => $left, len => 10);
    ok($op->cancel, 'cancel accepted');
    ok($op->is_cancelled, 'op is cancelled');
};

done_testing;
