use v5.36;
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);

use Linux::Event::HTTP::Client::Connection;
use Linux::Event::HTTP::Request;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

{
    package T::ClientUpgradedProtocol;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Scalar::Util qw(refaddr);

    sub on_data ($self, $bytes) {
        my $state = $self->data;
        $state->{target_hits}++;
        $state->{target_input} .= $bytes;
        $state->{target_class} = ref($self);
        $state->{same_object} = refaddr($self) == $state->{http_ref} ? 1 : 0;
    }
}

sub upgrade_request (%extra) {
    return Linux::Event::HTTP::Request->new(
        method  => 'GET',
        target  => '/switch',
        headers => [
            [ Host       => 'example.test' ],
            [ Connection => 'keep-alive, Upgrade' ],
            [ Upgrade    => 'test-proto' ],
        ],
        %extra,
    );
}

subtest '101 transitions the same live connection and preserves post-head bytes' => sub {
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
                    "HTTP/1.1 101 Switching Protocols\r\n" .
                    "Connection: Upgrade\r\n" .
                    "Upgrade: test-proto\r\n" .
                    "X-Handshake: ok\r\n" .
                    "\r\n" .
                    "WELCOME"
                );
            },
        },
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "client Upgrade handoff test timed out\n";
        },
    );

    my $state = {
        target_hits  => 0,
        target_input => '',
        sequence     => [],
    };
    my $client = Linux::Event::HTTP::Client::Connection->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $listener->port,
        data => $state,
    );
    $state->{http_ref} = refaddr($client);

    my $tx = $client->request(
        upgrade_request(),
        upgrade_to => 'T::ClientUpgradedProtocol',
        on_response => sub ($transaction, $response) {
            push @{$state->{sequence}}, 'response';
            $state->{status} = $response->status;
            $state->{handshake} = $response->header('X-Handshake');
            $state->{response_attached}
                = refaddr($transaction->response) == refaddr($response) ? 1 : 0;
            $state->{response_incomplete} = $response->is_complete ? 0 : 1;
        },
        on_upgrade => sub ($transaction, $response, $connection) {
            push @{$state->{sequence}}, 'upgrade';
            $state->{upgrade_tx_complete} = $transaction->is_complete ? 1 : 0;
            $state->{upgrade_response_complete} = $response->is_complete ? 1 : 0;
            $state->{upgrade_class} = ref($connection);
            $state->{upgrade_same_object}
                = refaddr($connection) == $state->{http_ref} ? 1 : 0;
        },
        on_complete => sub ($transaction) {
            push @{$state->{sequence}}, 'complete';
            $state->{complete_tx} = $transaction->is_complete ? 1 : 0;
            $guard->cancel;
            $client->close;
            $listener->close;
            $loop->stop;
        },
        on_error => sub ($transaction, $error) {
            die "client Upgrade failed: $error\n";
        },
    );

    $loop->run;

    is($state->{status}, 101, '101 Response is attached to the Transaction');
    is($state->{handshake}, 'ok', '101 response headers remain available');
    ok($state->{response_attached}, 'on_response sees the final attached Response');
    ok($state->{response_incomplete}, 'Response is not complete before handoff commit');
    ok($state->{upgrade_tx_complete}, 'Transaction completes before on_upgrade');
    ok($state->{upgrade_response_complete}, '101 Response completes before on_upgrade');
    is($state->{upgrade_class}, 'T::ClientUpgradedProtocol',
        'on_upgrade receives the transitioned connection class');
    ok($state->{upgrade_same_object}, 'on_upgrade receives the same live stream object');
    ok($state->{complete_tx}, 'on_complete follows a successful Upgrade Transaction');
    is_deeply($state->{sequence}, [qw(response upgrade complete)],
        'Upgrade callbacks run in response, upgrade, complete order');
    is($state->{target_hits}, 1, 'target protocol receives preserved post-101 input');
    is($state->{target_input}, 'WELCOME',
        'bytes following the 101 head in the same read survive handoff');
    is($state->{target_class}, 'T::ClientUpgradedProtocol',
        'same live object is reblessed before target data delivery');
    ok($state->{same_object}, 'target protocol retains connection object identity');
    ok($tx->is_complete, 'returned Transaction remains successfully complete');
};

subtest 'bare 101 without upgrade_to remains a protocol error' => sub {
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
                    "HTTP/1.1 101 Switching Protocols\r\n" .
                    "Connection: Upgrade\r\n" .
                    "Upgrade: test-proto\r\n\r\n"
                );
            },
        },
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "bare 101 test timed out\n";
        },
    );

    my $client = Linux::Event::HTTP::Client::Connection->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $listener->port,
    );
    my $state = {};
    my $tx = $client->request(
        upgrade_request(),
        on_error => sub ($transaction, $error) {
            $state->{error} = "$error";
            $guard->cancel;
            $listener->close;
            $loop->stop;
        },
    );

    $loop->run;

    like($state->{error}, qr/101 Upgrade requires upgrade_to/,
        'unexpected switching response requires an explicit handoff target');
    is($tx->state, 'error', 'unexpected 101 fails the Transaction');
    ok($client->is_closed, 'unexpected 101 closes the HTTP connection');
};

subtest 'invalid Upgrade selection is rejected before transition' => sub {
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
                    "HTTP/1.1 101 Switching Protocols\r\n" .
                    "Connection: Upgrade\r\n" .
                    "Upgrade: other-proto\r\n\r\n"
                );
            },
        },
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "invalid client Upgrade test timed out\n";
        },
    );

    my $client = Linux::Event::HTTP::Client::Connection->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $listener->port,
    );
    my $state = { upgrade_hits => 0 };
    my $tx = $client->request(
        upgrade_request(),
        upgrade_to => 'T::ClientUpgradedProtocol',
        on_upgrade => sub ($transaction, $response, $connection) {
            ++$state->{upgrade_hits};
        },
        on_error => sub ($transaction, $error) {
            $state->{error} = "$error";
            $guard->cancel;
            $listener->close;
            $loop->stop;
        },
    );

    $loop->run;

    is($state->{upgrade_hits}, 0, 'invalid protocol selection never transitions');
    like($state->{error}, qr/selected protocol not offered by request: other-proto/,
        'invalid selected Upgrade protocol is reported clearly');
    is($tx->state, 'error', 'invalid Upgrade selection fails the Transaction');
    ok($client->is_closed, 'invalid Upgrade response closes the connection');
};

subtest 'invalid Upgrade request is rejected before wire output' => sub {
    my $loop = Linux::Event::Loop->new;
    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => {
            on_data => sub ($stream, $bytes) {
                die "invalid Upgrade request unexpectedly reached the wire\n";
            },
        },
    );

    my $client = Linux::Event::HTTP::Client::Connection->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $listener->port,
    );

    my $bad = Linux::Event::HTTP::Request->new(
        method  => 'POST',
        target  => '/switch',
        headers => [
            [ Host       => 'example.test' ],
            [ Connection => 'Upgrade' ],
            [ Upgrade    => 'test-proto' ],
        ],
        body => 'x',
    );

    my $ok = eval {
        $client->request(
            $bad,
            upgrade_to => 'T::ClientUpgradedProtocol',
        );
        1;
    };
    ok(!$ok, 'body-bearing client Upgrade request is rejected synchronously');
    like($@, qr/Upgrade Request body must be empty/,
        'body-bearing Upgrade rejection is explicit');

    $client->close;
    $listener->close;
};

done_testing;
