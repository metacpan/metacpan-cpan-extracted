use v5.36;
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);

use Linux::Event::HTTP::Request;
use Linux::Event::HTTP::Response;
use Linux::Event::HTTP::Transaction;

{
    package T::BodyController;

    sub new ($class) {
        return bless {
            writes     => [],
            next_write => 1,
        }, $class;
    }

    sub _write_http_response_body ($self, $transaction, $bytes, $final, $operation) {
        push @{$self->{writes}}, [ $transaction, $bytes, $final, $operation ];
        return $self->{next_write};
    }

    sub _cancel_http_transaction ($self, $transaction) {
        $transaction->_mark_cancelled;
        return;
    }
}

sub new_transaction ($controller = T::BodyController->new) {
    my $request = Linux::Event::HTTP::Request->new(
        method => 'GET',
        target => '/',
    );
    my $response = Linux::Event::HTTP::Response->new;
    my $transaction = Linux::Event::HTTP::Transaction->_new(
        request    => $request,
        controller => $controller,
    );
    $transaction->_set_response($response);
    $transaction->_activate;
    return ($transaction, $request, $response, $controller);
}

my ($transaction, $request, $response, $controller) = new_transaction();

ok(!$response->can('write'), 'Response does not expose streaming write');
ok(!$response->can('complete'), 'Response does not expose body completion operation');
ok(!$response->can('stream_body'), 'Response does not expose a streaming producer');
ok(!defined $response->body, 'response starts without a scalar body');

$response->body("hello\n");
is($response->body, "hello\n", 'body setter stores complete scalar body bytes');
ok($response->is_complete, 'scalar body completes the Response message');

my $ok = eval { $transaction->response_body; 1 };
ok(!$ok, 'scalar body and incremental producer are mutually exclusive');
like($@, qr/scalar body/, 'scalar-versus-producer error is clear');

($transaction, $request, $response, $controller) = new_transaction();

my ($drains, $cancels) = (0, 0);
my $stream;
$stream = $transaction->response_body(
    on_drain => sub ($body) {
        ++$drains;
        is(refaddr($body), refaddr($stream), 'on_drain receives the same body producer');
    },
    on_cancel => sub ($body) {
        ++$cancels;
    },
);

ok(!$response->is_complete,
    'selecting an incremental producer leaves Response body incomplete');
is(refaddr($transaction->response_body), refaddr($stream),
    'argumentless response_body returns the same producer');

$ok = eval { $transaction->response_body(on_cancel => sub {}); 1 };
ok(!$ok, 'producer callbacks can only be configured on first response_body call');
like($@, qr/only be supplied when the producer is created/,
    'producer reconfiguration rejection is clear');

$ok = eval { $response->body('nope'); 1 };
ok(!$ok, 'incremental producer and scalar body are mutually exclusive');
like($@, qr/incremental body producer/, 'producer-versus-scalar error is clear');

$controller->{next_write} = 0;
ok(!$stream->write('abc'), 'producer write preserves downstream false backpressure return');
is(refaddr($controller->{writes}[0][0]), refaddr($transaction),
    'controller receives the owning Transaction');
is_deeply(
    [ @{$controller->{writes}[0]}[1 .. 3] ],
    [ 'abc', 0, 'response_body->write' ],
    'producer delegates body bytes without owning a second queue',
);

$stream->_drain;
is($drains, 1, 'on_drain fires after a blocked producer is drained');
$stream->_drain;
is($drains, 1, 'drain callback does not repeat without another blocked write');

$controller->{next_write} = 1;
$stream->write('def');
$stream->complete('ghi');
ok($stream->is_complete, 'producer reports completion');
ok(!$stream->is_cancelled, 'completed producer is not cancelled');
ok($response->is_complete,
    'producer completion marks the Response message complete');
is_deeply(
    [ @{$controller->{writes}[-1]}[1 .. 3] ],
    [ 'ghi', 1, 'response_body->complete' ],
    'producer completion delegates optional final bytes',
);

$ok = eval { $stream->write('late'); 1 };
ok(!$ok, 'write after producer completion is rejected');
like($@, qr/already complete/, 'post-completion write rejection is clear');

($transaction, $request, $response, $controller) = new_transaction();
my $cancelled = $transaction->response_body(
    on_cancel => sub ($body) { ++$cancels },
);
$transaction->_mark_cancelled;
ok($cancelled->is_cancelled, 'Transaction cancellation marks producer cancelled');
is($cancels, 1, 'on_cancel fires once');
$cancelled->_cancel;
is($cancels, 1, 'repeated producer cancellation is idempotent');

$ok = eval { $cancelled->complete; 1 };
ok(!$ok, 'cancelled producer cannot complete');
like($@, qr/cancelled/, 'cancelled producer completion rejection is clear');

($transaction, $request, $response, $controller) = new_transaction();
$ok = eval { $transaction->response_body(on_drain => 'no'); 1 };
ok(!$ok, 'non-coderef on_drain is rejected');
like($@, qr/on_drain must be a coderef/, 'on_drain validation is clear');
$response->body('still scalar');
is($response->body, 'still scalar',
    'rejected producer callback does not select incremental body mode');

($transaction, $request, $response, $controller) = new_transaction();
$ok = eval { $transaction->response_body(unknown => 1); 1 };
ok(!$ok, 'unknown response_body option is rejected');
like($@, qr/unknown option/, 'unknown response_body option error is clear');
$response->body('still scalar');
is($response->body, 'still scalar',
    'rejected producer option does not select incremental body mode');

done_testing;
