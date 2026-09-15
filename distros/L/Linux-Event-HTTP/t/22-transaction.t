use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::HTTP::Request;
use Linux::Event::HTTP::Response;
use Linux::Event::HTTP::Transaction;

{
    package T::TransactionController;

    sub new ($class) {
        return bless { cancel_calls => 0, last_transaction => undef }, $class;
    }

    sub _cancel_http_transaction ($self, $transaction) {
        ++$self->{cancel_calls};
        $self->{last_transaction} = $transaction;
        return;
    }
}

my $request = Linux::Event::HTTP::Request->new(
    method => 'GET',
    target => '/',
);

my $controller = T::TransactionController->new;
my $tx = Linux::Event::HTTP::Transaction->_new(
    request    => $request,
    controller => $controller,
);

is($tx->request, $request, 'Transaction retains its Request');
ok(!defined $tx->response, 'Response is absent before response head exists');
is($tx->state, 'pending', 'Transaction begins pending');
ok(!$tx->is_complete, 'pending Transaction is not complete');
ok(!$tx->is_cancelled, 'pending Transaction is not cancelled');
ok(!$tx->is_terminal, 'pending Transaction is not terminal');
ok(!defined $tx->error, 'pending Transaction has no error');

$tx->_activate;
is($tx->state, 'active', 'Transaction can enter active state');

my $response = Linux::Event::HTTP::Response->new(status => 200);
is($tx->_set_response($response), $response, 'response attachment returns Response');
is($tx->response, $response, 'Transaction exposes attached Response');

my $duplicate = eval { $tx->_set_response(Linux::Event::HTTP::Response->new); 1 };
ok(!$duplicate, 'Transaction accepts only one Response');
like($@, qr/already has a Response/, 'duplicate Response error is clear');

$tx->_mark_complete;
is($tx->state, 'complete', 'successful exchange becomes complete');
ok($tx->is_complete, 'complete Transaction reports success');
ok($tx->is_terminal, 'complete Transaction is terminal');
$tx->cancel;
is($controller->{cancel_calls}, 0, 'cancel after completion is a no-op');
is($tx->state, 'complete', 'cancel does not alter completed Transaction');

my $cancel_controller = T::TransactionController->new;
my $cancel_tx = Linux::Event::HTTP::Transaction->_new(
    request => Linux::Event::HTTP::Request->new(
        method => 'POST',
        target => '/upload',
    ),
    controller => $cancel_controller,
);
$cancel_tx->cancel;
is($cancel_controller->{cancel_calls}, 1, 'cancel invokes controller once');
is($cancel_controller->{last_transaction}, $cancel_tx,
    'controller receives the Transaction being cancelled');
is($cancel_tx->state, 'cancelled', 'cancelled Transaction has cancelled state');
ok($cancel_tx->is_cancelled, 'cancelled Transaction reports cancellation');
ok($cancel_tx->is_terminal, 'cancelled Transaction is terminal');
$cancel_tx->cancel;
is($cancel_controller->{cancel_calls}, 1, 'repeated cancellation is idempotent');

my $error_tx = Linux::Event::HTTP::Transaction->_new(request => $request);
$error_tx->_fail('connection reset');
is($error_tx->state, 'error', 'failed Transaction enters error state');
is($error_tx->error, 'connection reset', 'failed Transaction retains error');
ok($error_tx->is_terminal, 'failed Transaction is terminal');
ok(!$error_tx->is_complete, 'failed Transaction is not successful completion');

my $response_less = Linux::Event::HTTP::Transaction->_new(request => $request);
my $ok = eval { $response_less->_mark_complete; 1 };
ok(!$ok, 'Transaction cannot complete before a Response exists');
like($@, qr/before it has a Response/, 'response-less completion error is clear');

$ok = eval {
    Linux::Event::HTTP::Transaction->_new(request => bless({}, 'T::NotRequest'));
    1;
};
ok(!$ok, 'Transaction rejects non-Request object');
like($@, qr/requires a Linux::Event::HTTP::Request/, 'invalid Request error is clear');

$ok = eval {
    Linux::Event::HTTP::Transaction->_new(request => $request, controller => {});
    1;
};
ok(!$ok, 'Transaction controller must be an object');
like($@, qr/controller must be an object/, 'invalid controller error is clear');

done_testing;
