use v5.36;
use Test2::V0;
use Time::HiRes qw(sleep);

use Linux::Event::Proactor;

subtest '_unregister_op removes exactly once' => sub {
    my $loop = Linux::Event::Proactor->new;

    my $op = $loop->after(1);

    is($loop->live_op_count, 1, 'live count incremented');
    ok(defined($op->_backend_token), 'token assigned');

    my $token = $op->_backend_token;

    my $first = $loop->_unregister_op($token);
    ok(defined($first), 'first unregister returns an op');
    is(ref($first), ref($op), 'returned object has expected class');
    is($first->_backend_token, $token, 'returned op has expected token');
    is($loop->live_op_count, 0, 'live count decremented');

    my $second = $loop->_unregister_op($token);
    is($second, undef, 'second unregister returns undef');
    is($loop->live_op_count, 0, 'live count not decremented twice');
};

subtest 'cancel unregisters pending timer cleanly' => sub {
    my $loop = Linux::Event::Proactor->new;

    my $op = $loop->after(10);

    is($loop->live_op_count, 1, 'one live op before cancel');

    ok($op->cancel, 'cancel accepted');

    is($loop->live_op_count, 0, 'no live ops after cancel');
    ok(!exists $loop->{ops_by_token}{ $op->_backend_token }, 'token removed from registry');
    ok($op->is_cancelled, 'op settled cancelled');
};

subtest 'expired timer unregisters cleanly' => sub {
    my $loop = Linux::Event::Proactor->new;

    my $op = $loop->after(0.01);

    is($loop->live_op_count, 1, 'one live op before expiry');

    sleep 0.02;
    my $n = $loop->run_once;

    ok($n >= 1, 'progress after expiry');
    is($loop->live_op_count, 0, 'no live ops after expiry');
    ok(!exists $loop->{ops_by_token}{ $op->_backend_token }, 'token removed from registry');
    ok($op->success, 'op settled success');
};

done_testing;
