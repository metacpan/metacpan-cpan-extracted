use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::HTTP::Server::Connection;
use Linux::Event::HTTP::Transaction;

{
    package T::ServerTransactionConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub on_request ($self, $request, $response) {
        my $transaction = $self->transaction;
        $self->data->{transaction} = $transaction;
        $self->data->{request} = $request;
        $self->data->{response_object} = $response;
        $self->data->{request_complete_on_request}
            = $request->is_complete ? 1 : 0;
        $self->data->{transaction_state_on_request}
            = $transaction->state;
        return;
    }

    sub on_body ($self, $request, $response, $bytes) {
        $self->data->{body} .= $bytes;
        return;
    }

    sub on_request_end ($self, $request, $response) {
        $self->data->{request_complete_on_end}
            = $request->is_complete ? 1 : 0;
        $self->data->{transaction_state_on_end}
            = $self->transaction->state;
        $response->body("ok\n");
        return;
    }
}

my $loop = Linux::Event::Loop->new;
my $state = {
    body     => '',
    response => '',
};

my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    stream => {
        class => 'T::ServerTransactionConnection',
        data  => $state,
    },
);

my $client = Linux::Event::IO::Sock::Stream->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => $listener->port,
    on_ready => sub ($stream) {
        $stream->write(
            "POST /upload HTTP/1.1\r\n" .
            "Host: example.test\r\n" .
            "Content-Length: 4\r\n" .
            "Connection: close\r\n" .
            "\r\n" .
            "data"
        );
    },
    on_data => sub ($stream, $bytes) {
        $state->{response} .= $bytes;
    },
    on_eof => sub ($stream) {
        $stream->close;
        $listener->close;
        $loop->stop;
    },
    on_error => sub ($stream, $error) {
        die "server Transaction test client failed: $error\n";
    },
);

$loop->run;

isa_ok($state->{transaction}, 'Linux::Event::HTTP::Transaction');
is($state->{transaction}->request, $state->{request},
    'server Transaction owns the dispatched Request');
is($state->{transaction}->response, $state->{response_object},
    'server Transaction owns the paired Response');
is($state->{transaction_state_on_request}, 'active',
    'server Transaction is active during on_request');
ok(!$state->{request_complete_on_request},
    'bodyful Request is incomplete while only its head has been dispatched');
is($state->{body}, 'data', 'request body is delivered incrementally');
ok($state->{request_complete_on_end},
    'Request becomes complete at its actual body boundary');
is($state->{transaction_state_on_end}, 'active',
    'Transaction remains active while on_request_end configures the response');
ok($state->{transaction}->is_complete,
    'server Transaction completes after request and response output complete');
like($state->{response}, qr/\r\n\r\nok\n\z/,
    'server Transaction still emits the expected response');

ok(!$state->{response_object}->can('connection'),
    'server Response remains independent of the carrying Connection');
ok(!$state->{response_object}->can('request'),
    'server Response remains independent of its peer Request');

# The native default-final response builder is exercised through the real
# Server::Connection path in t/50-final-response.t. Do not recreate a synthetic
# bound Response merely to unit-test a transport optimization.

done_testing;
