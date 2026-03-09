use v5.36;
use Test2::V0;

use Linux::Event::Proactor;

subtest 'callback and data are cleared after callback dispatch' => sub {
    my $loop = Linux::Event::Proactor->new;
    my $seen;

    my $op = $loop->_new_op(
        kind => 'timeout',
        data => 'ctx',
        on_complete => sub ($op, $result, $data) {
            $seen = $data;
        },
    );

    $op->_settle_success({ expired => 1 });

    is($op->data, 'ctx', 'data still present before callback dispatch');

    $loop->run_once;

    is($seen, 'ctx', 'callback received original data');
    is($op->data, undef, 'data cleared after callback');
};

subtest 'post-terminal on_complete followed by dispatch clears callback/data' => sub {
    my $loop = Linux::Event::Proactor->new;
    my $seen;

    my $op = $loop->_new_op(
        kind => 'timeout',
        data => 'ctx',
    );

    $op->_settle_success({ expired => 1 });

    $op->on_complete(sub ($op, $result, $data) {
        $seen = [$op->state, $result, $data];
    });

    $loop->run_once;

    is($seen, ['done', { expired => 1 }, 'ctx'], 'late callback saw terminal truth');
    is($op->data, undef, 'data cleared after late callback dispatch');
};

done_testing;
