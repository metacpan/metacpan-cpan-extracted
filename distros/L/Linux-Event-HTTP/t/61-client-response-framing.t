use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::HTTP::Client::Connection;
use Linux::Event::HTTP::Request;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

sub request_for ($method = 'GET', $target = '/', %extra) {
    return Linux::Event::HTTP::Request->new(
        method  => $method,
        target  => $target,
        headers => [ [ Host => 'example.test' ] ],
        %extra,
    );
}

subtest 'informational then close-delimited final response' => sub {
    my $loop = Linux::Event::Loop->new;
    my $sent = 0;
    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => {
            on_data => sub ($stream, $bytes) {
                return if $sent++;
                $stream->write(
                    "HTTP/1.1 100 Continue\r\n\r\n" .
                    "HTTP/1.0 200 OK\r\n" .
                    "Content-Type: text/plain\r\n" .
                    "\r\n" .
                    "close-delimited"
                );
                $stream->end;
            },
        },
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "informational/close-delimited test timed out\n";
        },
    );

    my $client = Linux::Event::HTTP::Client::Connection->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $listener->port,
    );

    my $state = {
        informational => [],
        body          => '',
    };

    my $tx = $client->request(
        request_for('POST', '/upload', body => 'abc'),
        on_informational => sub ($transaction, $response) {
            push @{$state->{informational}}, [
                $response->status,
                $response->is_complete ? 1 : 0,
                defined($transaction->response) ? 1 : 0,
            ];
        },
        on_response => sub ($transaction, $response) {
            $state->{final_status} = $response->status;
            $state->{final_version} = $response->version;
            $state->{final_incomplete} = $response->is_complete ? 0 : 1;
        },
        on_body => sub ($transaction, $response, $bytes) {
            $state->{body} .= $bytes;
        },
        on_complete => sub ($transaction) {
            $state->{tx_complete} = $transaction->is_complete ? 1 : 0;
            $state->{message_complete}
                = $transaction->response->is_complete ? 1 : 0;
            $state->{closed} = $client->is_closed ? 1 : 0;
            $guard->cancel;
            $listener->close;
            $loop->stop;
        },
        on_error => sub ($transaction, $error) {
            die "close-delimited client failed: $error\n";
        },
    );

    $loop->run;

    is_deeply(
        $state->{informational},
        [ [ 100, 1, 0 ] ],
        '100 response is complete but is not attached as the final Transaction Response',
    );
    is($state->{final_status}, 200, 'final response follows informational response');
    is($state->{final_version}, '1.0', 'client accepts HTTP/1.0 final response');
    ok($state->{final_incomplete}, 'close-delimited final response is incomplete at head delivery');
    is($state->{body}, 'close-delimited', 'close-delimited bytes are delivered until EOF');
    ok($state->{tx_complete}, 'close-delimited Transaction completes at EOF');
    ok($state->{message_complete}, 'close-delimited Response completes at EOF');
    ok($state->{closed}, 'close-delimited completion leaves connection closed');
    ok($tx->is_complete, 'returned Transaction remains successfully complete');
};

subtest 'ambiguous Transfer-Encoding plus Content-Length is rejected' => sub {
    my $loop = Linux::Event::Loop->new;
    my $sent = 0;
    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => {
            on_data => sub ($stream, $bytes) {
                return if $sent++;
                $stream->write(
                    "HTTP/1.1 200 OK\r\n" .
                    "Content-Length: 4\r\n" .
                    "Transfer-Encoding: chunked\r\n" .
                    "\r\n" .
                    "4\r\ntest\r\n0\r\n\r\n"
                );
            },
        },
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "ambiguous framing test timed out\n";
        },
    );

    my $client = Linux::Event::HTTP::Client::Connection->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $listener->port,
    );

    my $state = { response_hits => 0, error_hits => 0 };
    my $tx = $client->request(
        request_for(),
        on_response => sub ($transaction, $response) {
            ++$state->{response_hits};
        },
        on_complete => sub ($transaction) {
            die "ambiguous response unexpectedly completed\n";
        },
        on_error => sub ($transaction, $error) {
            ++$state->{error_hits};
            $state->{error} = "$error";
            $state->{closed} = $client->is_closed ? 1 : 0;
            $guard->cancel;
            $listener->close;
            $loop->stop;
        },
    );

    $loop->run;

    is($state->{response_hits}, 0,
        'invalid response framing is rejected before on_response');
    is($state->{error_hits}, 1, 'invalid framing reports one terminal error');
    like($state->{error}, qr/both Transfer-Encoding and Content-Length/,
        'ambiguous framing error is explicit');
    is($tx->state, 'error', 'Transaction enters error state');
    ok($client->is_closed, 'protocol framing error closes the connection');
};

subtest 'cancelling a body closes rather than reusing the HTTP/1 connection' => sub {
    my $loop = Linux::Event::Loop->new;
    my $sent = 0;
    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => {
            on_data => sub ($stream, $bytes) {
                return if $sent++;
                $stream->write(
                    "HTTP/1.1 200 OK\r\n" .
                    "Content-Length: 100\r\n" .
                    "\r\n" .
                    "partial"
                );
            },
        },
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "client cancellation test timed out\n";
        },
    );

    my $client = Linux::Event::HTTP::Client::Connection->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $listener->port,
    );

    my $state = {
        body          => '',
        complete_hits => 0,
        error_hits    => 0,
    };

    my $tx = $client->request(
        request_for(),
        on_body => sub ($transaction, $response, $bytes) {
            $state->{body} .= $bytes;
            $transaction->cancel;
            $state->{cancelled} = $transaction->is_cancelled ? 1 : 0;
            $state->{response_complete} = $response->is_complete ? 1 : 0;
            $state->{closed} = $client->is_closed ? 1 : 0;
            $guard->cancel;
            $listener->close;
            $loop->stop;
        },
        on_complete => sub ($transaction) {
            ++$state->{complete_hits};
        },
        on_error => sub ($transaction, $error) {
            ++$state->{error_hits};
        },
    );

    $loop->run;

    is($state->{body}, 'partial', 'body callback receives bytes before cancellation');
    ok($state->{cancelled}, 'Transaction reports cancellation');
    ok(!$state->{response_complete}, 'cancelled partial Response remains incomplete');
    ok($state->{closed}, 'cancellation closes the HTTP/1 connection');
    is($state->{complete_hits}, 0, 'cancelled Transaction does not call on_complete');
    is($state->{error_hits}, 0, 'explicit cancellation is distinct from on_error');
    is($tx->state, 'cancelled', 'returned Transaction remains cancelled');
};

done_testing;
