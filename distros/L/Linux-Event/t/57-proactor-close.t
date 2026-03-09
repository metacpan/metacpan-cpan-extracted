use v5.36;
use Test::More;

use Linux::Event::Proactor;

my $loop = Linux::Event::Proactor->new(backend => 'fake');

{
    my $called = 0;
    open my $fh, '<', __FILE__ or die $!;

    my $op = $loop->close(
        fh => $fh,
        on_complete => sub ($op, $result, $ctx) {
            $called++;
            is($op->state, 'done', 'close op done');
            is_deeply($result, {}, 'close result');
        },
    );

    is($op->state, 'pending', 'close starts pending');
    $loop->_fake_complete_close_success($op->_backend_token);
    is($called, 0, 'callback not inline');
    $loop->drain_callbacks;
    is($called, 1, 'callback drained');
}

{
    open my $fh, '<', __FILE__ or die $!;

    my $op = $loop->close(fh => $fh);
    $loop->_fake_complete_close_error($op->_backend_token, code => 9, name => 'EBADF');
    is($op->state, 'done', 'close failure state');
    ok($op->failed, 'close failure recorded');
    is($op->error->code, 9, 'close failure errno');
}

{
    open my $fh, '<', __FILE__ or die $!;

    my $op = $loop->close(fh => $fh);
    ok($op->cancel, 'close cancel succeeds');
    is($op->state, 'cancelled', 'close cancelled');
}

done_testing;
