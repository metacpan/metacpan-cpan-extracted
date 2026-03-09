use v5.36;
use Test2::V0;
use Socket qw(AF_UNIX SOCK_STREAM pack_sockaddr_un);

use Linux::Event::Proactor;

socketpair(my $listen_fh, my $client_fh, AF_UNIX, SOCK_STREAM, 0)
    or die "socketpair failed: $!";

subtest 'accept success settles with expected result shape' => sub {
    my $loop = Linux::Event::Proactor->new;
    my @calls;

    my $addr = pack_sockaddr_un('/tmp/fake-peer.sock');

    my $op = $loop->accept(
        fh   => $listen_fh,
        data => 'ctx',
        on_complete => sub ($op, $result, $data) {
            push @calls, [$op->state, $op->success, $op->failed, $result, $data];
        },
    );

    ok($op->is_pending, 'accept starts pending');

    my $token = $op->_backend_token;
    $loop->_fake_complete_accept_success($token, $client_fh, $addr);

    ok($op->is_done, 'accept is done');
    ok($op->success, 'accept success true');
    ok(!$op->failed, 'accept failed false');
    is(
        $op->result,
        {
            fh   => $client_fh,
            addr => $addr,
        },
        'accept result stored',
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
            fh   => $client_fh,
            addr => $addr,
        },
        'callback got expected result',
    );
    is($calls[0][4], 'ctx', 'callback got data');

    ok(!exists $loop->{ops_by_token}{$token}, 'op registry entry removed');
};

subtest 'accept error settles with Linux::Event::Error' => sub {
    my $loop = Linux::Event::Proactor->new;
    my @calls;

    my $op = $loop->accept(
        fh   => $listen_fh,
        data => 'ctx',
        on_complete => sub ($op, $result, $data) {
            push @calls, [$op->state, $op->success, $op->failed, $result, $op->error, $data];
        },
    );

    my $token = $op->_backend_token;
    $loop->_fake_complete_accept_error(
        $token,
        code    => 24,
        name    => 'EMFILE',
        message => 'Too many open files',
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

subtest 'accept cancel settles cancelled' => sub {
    my $loop = Linux::Event::Proactor->new;

    my $op = $loop->accept(
        fh => $listen_fh,
    );

    ok($op->cancel, 'cancel accepted');
    ok($op->is_cancelled, 'op is cancelled');
};

done_testing;
