use v5.36;
use Test2::V0;

BEGIN {
    eval {
        require IO::Uring;
        1;
    } or skip_all("IO::Uring not available: $@");
}

use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use Linux::Event::Proactor;

subtest 'real uring write completes and callback fires' => sub {

    socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair failed: $!";

    my $loop = Linux::Event::Proactor->new(
        backend    => 'uring',
        queue_size => 64,
    );

    my @calls;

    my $op = $loop->write(
        fh   => $left,
        buf  => 'hello uring',
        data => 'ctx',
        on_complete => sub ($op, $result, $data) {
            push @calls, [$op->state, $op->success, $result, $data];
        },
    );

    ok($op->is_pending, 'write starts pending');

    my $n = $loop->run_once;
    ok($n >= 1, 'run_once made progress');

    ok($op->is_done, 'write is done');
    ok($op->success, 'write succeeded');
    is($op->result, { bytes => 11 }, 'write result shape is correct');

    is(scalar(@calls), 1, 'callback ran once');
    is($calls[0][0], 'done', 'callback saw done');
    is($calls[0][1], 1, 'callback saw success');
    is($calls[0][2], { bytes => 11 }, 'callback got result');
    is($calls[0][3], 'ctx', 'callback got data');

    my $buf = '';
    my $got = sysread($right, $buf, 64);
    is($got, 11, 'peer read expected byte count');
    is($buf, 'hello uring', 'peer saw expected payload');
};

subtest 'real uring read completes and callback fires' => sub {

    socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair failed: $!";

    my $written = syswrite($right, 'ping');
    is($written, 4, 'seeded peer with 4 bytes');

    my $loop = Linux::Event::Proactor->new(
        backend    => 'uring',
        queue_size => 64,
    );

    my @calls;

    my $op = $loop->read(
        fh   => $left,
        len  => 16,
        data => 'ctx',
        on_complete => sub ($op, $result, $data) {
            push @calls, [$op->state, $op->success, $result, $data];
        },
    );

    ok($op->is_pending, 'read starts pending');

    my $n = $loop->run_once;
    ok($n >= 1, 'run_once made progress');

    ok($op->is_done, 'read is done');
    ok($op->success, 'read succeeded');

    is(
        $op->result,
        {
            bytes => 4,
            data  => 'ping',
            eof   => 0,
        },
        'read result shape is correct',
    );

    is(scalar(@calls), 1, 'callback ran once');
    is($calls[0][0], 'done', 'callback saw done');
    is($calls[0][1], 1, 'callback saw success');

    is(
        $calls[0][2],
        {
            bytes => 4,
            data  => 'ping',
            eof   => 0,
        },
        'callback got result',
    );

    is($calls[0][3], 'ctx', 'callback got data');
};

done_testing;
