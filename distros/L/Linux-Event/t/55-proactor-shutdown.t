use v5.36;
use Test2::V0;
use Socket qw(SHUT_RD SHUT_WR SHUT_RDWR);

use lib 'lib';

use Linux::Event::Proactor;

subtest 'shutdown success with semantic how values' => sub {
    my $loop = Linux::Event::Proactor->new(backend => 'fake');

    my @seen;

    my $op1 = $loop->shutdown(
        fh => bless({}, 'Local::FH'),
        how => 'read',
        data => 'r',
        on_complete => sub ($op, $result, $ctx) {
            push @seen, [$op->kind, $result, $ctx];
        },
    );

    my $op2 = $loop->shutdown(
        fh => bless({}, 'Local::FH'),
        how => 'write',
        data => 'w',
        on_complete => sub ($op, $result, $ctx) {
            push @seen, [$op->kind, $result, $ctx];
        },
    );

    my $op3 = $loop->shutdown(
        fh => bless({}, 'Local::FH'),
        how => 'both',
        data => 'b',
        on_complete => sub ($op, $result, $ctx) {
            push @seen, [$op->kind, $result, $ctx];
        },
    );

    ok $op1->is_pending, 'read shutdown pending before completion';
    ok $op2->is_pending, 'write shutdown pending before completion';
    ok $op3->is_pending, 'both shutdown pending before completion';

    is scalar(@seen), 0, 'callbacks not run inline';

    $loop->_fake_complete_shutdown_success($op1->_backend_token);
    $loop->_fake_complete_shutdown_success($op2->_backend_token);
    $loop->_fake_complete_shutdown_success($op3->_backend_token);

    is scalar(@seen), 0, 'callbacks still queued before drain';

    is $loop->drain_callbacks, 3, 'drained three callbacks';
    is \@seen, [
        ['shutdown', {}, 'r'],
        ['shutdown', {}, 'w'],
        ['shutdown', {}, 'b'],
    ], 'shutdown callbacks received expected payloads';

    ok $op1->success, 'read shutdown settled success';
    ok $op2->success, 'write shutdown settled success';
    ok $op3->success, 'both shutdown settled success';
};

subtest 'shutdown accepts numeric constants' => sub {
    my $loop = Linux::Event::Proactor->new(backend => 'fake');

    my $op = $loop->shutdown(
        fh  => bless({}, 'Local::FH'),
        how => SHUT_RDWR,
    );

    $loop->_fake_complete_shutdown_success($op->_backend_token);
    is $loop->drain_callbacks, 0, 'no callback to drain';
    ok $op->success, 'numeric constant accepted';
};

subtest 'shutdown failure and cancel' => sub {
    my $loop = Linux::Event::Proactor->new(backend => 'fake');

    my @seen;

    my $failed = $loop->shutdown(
        fh => bless({}, 'Local::FH'),
        how => 'both',
        data => 'failed',
        on_complete => sub ($op, $result, $ctx) {
            push @seen, [$op->state, ($op->error ? $op->error->code : undef), $ctx];
        },
    );

    my $cancelled = $loop->shutdown(
        fh => bless({}, 'Local::FH'),
        how => 'write',
        data => 'cancelled',
        on_complete => sub ($op, $result, $ctx) {
            push @seen, [$op->state, $result, $ctx];
        },
    );

    $loop->_fake_complete_shutdown_error(
        $failed->_backend_token,
        code => 107,
        name => 'ENOTCONN',
        message => 'Transport endpoint is not connected',
    );

    ok $cancelled->cancel, 'cancel returned true';

    is $loop->drain_callbacks, 2, 'drained failure and cancel callbacks';

    ok $failed->failed, 'shutdown failure settled';
    is $failed->error->code, 107, 'shutdown failure code preserved';

    ok $cancelled->is_cancelled, 'shutdown cancel settled cancelled';
    is \@seen, [
        ['done', 107, 'failed'],
        ['cancelled', undef, 'cancelled'],
    ], 'callback observations match';
};

subtest 'shutdown argument validation' => sub {
    my $loop = Linux::Event::Proactor->new(backend => 'fake');

    like dies { $loop->shutdown(fh => bless({}, 'Local::FH')) }, qr/how is required/, 'how required';
    like dies { $loop->shutdown(how => 'both') }, qr/fh is required/, 'fh required';
    like dies { $loop->shutdown(fh => bless({}, 'Local::FH'), how => 'sideways') }, qr/how must be/, 'invalid semantic how rejected';
    like dies { $loop->shutdown(fh => bless({}, 'Local::FH'), how => 999) }, qr/how must be/, 'invalid numeric how rejected';
    like dies { $loop->shutdown(fh => bless({}, 'Local::FH'), how => 'both', extra => 1) }, qr/unknown argument: extra/, 'unexpected arg rejected';
};

done_testing;
