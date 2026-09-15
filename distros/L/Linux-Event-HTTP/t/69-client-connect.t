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
    package T::ClientTunnelProtocol;
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

sub connect_request (%extra) {
    return Linux::Event::HTTP::Request->new(
        method  => 'CONNECT',
        target  => 'example.test:443',
        headers => [ [ Host => 'example.test:443' ] ],
        %extra,
    );
}

sub ordinary_request () {
    return Linux::Event::HTTP::Request->new(
        method  => 'GET',
        target  => '/after',
        headers => [ [ Host => 'example.test' ] ],
    );
}

subtest '2xx CONNECT transitions the same live connection at the head boundary' => sub {
    my $loop = Linux::Event::Loop->new;
    my $wire = '';
    my $sent = 0;
    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => {
            on_data => sub ($stream, $bytes) {
                $wire .= $bytes;
                return if $sent || $wire !~ /\r\n\r\n/;
                $sent = 1;
                $stream->write(
                    "HTTP/1.1 200 Connection Established\r\n" .
                    "Content-Length: 999\r\n" .
                    "Transfer-Encoding: chunked\r\n" .
                    "X-Proxy: ok\r\n" .
                    "\r\n" .
                    "TUNNEL-DATA"
                );
            },
        },
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "client CONNECT handoff test timed out\n";
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
        connect_request(),
        tunnel_to => 'T::ClientTunnelProtocol',
        on_response => sub ($transaction, $response) {
            push @{$state->{sequence}}, 'response';
            $state->{status} = $response->status;
            $state->{proxy_header} = $response->header('X-Proxy');
            $state->{response_attached}
                = refaddr($transaction->response) == refaddr($response) ? 1 : 0;
            $state->{response_incomplete} = $response->is_complete ? 0 : 1;
        },
        on_tunnel => sub ($transaction, $response, $connection) {
            push @{$state->{sequence}}, 'tunnel';
            $state->{tunnel_tx_complete} = $transaction->is_complete ? 1 : 0;
            $state->{tunnel_response_complete} = $response->is_complete ? 1 : 0;
            $state->{tunnel_class} = ref($connection);
            $state->{tunnel_same_object}
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
            die "client CONNECT failed: $error\n";
        },
    );

    $loop->run;

    like($wire, qr/\ACONNECT example\.test:443 HTTP\/1\.1\r\n/s,
        'CONNECT uses authority-form request target');
    like($wire, qr/\r\nHost: example\.test:443\r\n/s,
        'CONNECT Host matches the tunnel authority');
    is($state->{status}, 200, 'successful CONNECT Response is attached');
    is($state->{proxy_header}, 'ok', 'CONNECT response headers remain available');
    ok($state->{response_attached}, 'on_response sees the final attached Response');
    ok($state->{response_incomplete}, 'Response completes at the tunnel handoff boundary');
    ok($state->{tunnel_tx_complete}, 'Transaction completes before on_tunnel');
    ok($state->{tunnel_response_complete}, 'Response completes before on_tunnel');
    is($state->{tunnel_class}, 'T::ClientTunnelProtocol',
        'on_tunnel receives the transitioned connection class');
    ok($state->{tunnel_same_object}, 'CONNECT keeps the same live stream object');
    ok($state->{complete_tx}, 'on_complete follows successful tunnel handoff');
    is_deeply($state->{sequence}, [qw(response tunnel complete)],
        'CONNECT callbacks run in response, tunnel, complete order');
    is($state->{target_hits}, 1, 'target protocol receives post-head tunnel input');
    is($state->{target_input}, 'TUNNEL-DATA',
        'Content-Length and Transfer-Encoding on 2xx CONNECT are ignored');
    is($state->{target_class}, 'T::ClientTunnelProtocol',
        'same live object is reblessed before tunnel data delivery');
    ok($state->{same_object}, 'target protocol retains object identity');
    ok($tx->is_complete, 'returned CONNECT Transaction remains complete');
};

subtest 'non-2xx CONNECT stays HTTP and the connection remains reusable' => sub {
    my $loop = Linux::Event::Loop->new;
    my $wire = '';
    my $phase = 0;
    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => {
            on_data => sub ($stream, $bytes) {
                $wire .= $bytes;
                if ($phase == 0 && $wire =~ /\r\n\r\n/) {
                    $phase = 1;
                    $stream->write(
                        "HTTP/1.1 407 Proxy Authentication Required\r\n" .
                        "Content-Length: 4\r\n" .
                        "Connection: keep-alive\r\n" .
                        "\r\n" .
                        "nope"
                    );
                    $wire = '';
                } elsif ($phase == 1 && $wire =~ /\r\n\r\n/) {
                    $phase = 2;
                    $stream->write(
                        "HTTP/1.1 200 OK\r\n" .
                        "Content-Length: 2\r\n" .
                        "Connection: close\r\n" .
                        "\r\n" .
                        "ok"
                    );
                }
            },
        },
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "CONNECT rejection/reuse test timed out\n";
        },
    );

    my $client = Linux::Event::HTTP::Client::Connection->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $listener->port,
    );
    my $state = {
        body => '',
        tunnel_hits => 0,
        second_body => '',
    };

    my $first = $client->request(
        connect_request(),
        tunnel_to => 'T::ClientTunnelProtocol',
        on_response => sub ($transaction, $response) {
            $state->{first_status} = $response->status;
        },
        on_body => sub ($transaction, $response, $bytes) {
            $state->{body} .= $bytes;
        },
        on_tunnel => sub ($transaction, $response, $connection) {
            ++$state->{tunnel_hits};
        },
        on_complete => sub ($transaction) {
            $state->{first_complete} = $transaction->is_complete ? 1 : 0;
            $state->{class_after_407} = ref($client);
            $state->{second} = $client->request(
                ordinary_request(),
                on_body => sub ($tx, $res, $bytes) {
                    $state->{second_body} .= $bytes;
                },
                on_complete => sub ($tx) {
                    $state->{second_status} = $tx->response->status;
                    $state->{second_complete} = $tx->is_complete ? 1 : 0;
                    $guard->cancel;
                    $client->close if !$client->is_closed;
                    $listener->close;
                    $loop->stop;
                },
                on_error => sub ($tx, $error) {
                    die "request after rejected CONNECT failed: $error\n";
                },
            );
        },
        on_error => sub ($transaction, $error) {
            die "rejected CONNECT unexpectedly failed: $error\n";
        },
    );

    $loop->run;

    is($state->{first_status}, 407, 'non-2xx CONNECT response remains ordinary HTTP');
    is($state->{body}, 'nope', 'non-2xx CONNECT response body is delivered normally');
    is($state->{tunnel_hits}, 0, 'non-2xx CONNECT never enters tunnel mode');
    ok($state->{first_complete}, 'non-2xx CONNECT Transaction completes normally');
    is($state->{class_after_407}, 'Linux::Event::HTTP::Client::Connection',
        'failed CONNECT keeps the HTTP connection class');
    ok($first->is_complete, 'first CONNECT Transaction remains complete');
    is($state->{second_status}, 200, 'same HTTP connection accepts another request');
    is($state->{second_body}, 'ok', 'follow-up response body is parsed normally');
    ok($state->{second_complete}, 'follow-up Transaction completes');
};

subtest 'invalid CONNECT configurations fail before protocol execution' => sub {
    my $loop = Linux::Event::Loop->new;
    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => {
            on_data => sub ($stream, $bytes) { return; },
        },
    );
    my $client = Linux::Event::HTTP::Client::Connection->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $listener->port,
    );

    my $ok = eval { $client->request(connect_request()); 1 };
    ok(!$ok, 'CONNECT without tunnel_to is rejected');
    like($@, qr/CONNECT requires tunnel_to/,
        'missing tunnel target error is explicit');

    $ok = eval {
        $client->request(
            Linux::Event::HTTP::Request->new(
                method => 'CONNECT',
                target => '/not-authority',
                headers => [ [ Host => 'example.test:443' ] ],
            ),
            tunnel_to => 'T::ClientTunnelProtocol',
        );
        1;
    };
    ok(!$ok, 'non-authority CONNECT target is rejected');
    like($@, qr/authority-form host:port/,
        'invalid CONNECT target error is explicit');

    $ok = eval {
        $client->request(
            connect_request(body => 'x'),
            tunnel_to => 'T::ClientTunnelProtocol',
        );
        1;
    };
    ok(!$ok, 'CONNECT scalar body is rejected');
    like($@, qr/must not contain a scalar body/,
        'CONNECT body error is explicit');

    $ok = eval {
        $client->request(
            Linux::Event::HTTP::Request->new(
                method  => 'GET',
                target  => '/',
                headers => [ [ Host => 'example.test' ] ],
            ),
            tunnel_to => 'T::ClientTunnelProtocol',
        );
        1;
    };
    ok(!$ok, 'tunnel_to on a non-CONNECT request is rejected');
    like($@, qr/tunnel_to requires CONNECT method/,
        'method mismatch error is explicit');

    $ok = eval {
        $client->request(
            Linux::Event::HTTP::Request->new(
                method  => 'CONNECT',
                target  => 'example.test:443',
                headers => [ [ Host => 'other.test:443' ] ],
            ),
            tunnel_to => 'T::ClientTunnelProtocol',
        );
        1;
    };
    ok(!$ok, 'CONNECT Host mismatch is rejected');
    like($@, qr/Host must match/,
        'CONNECT Host mismatch error is explicit');

    ok(!defined($client->transaction),
        'rejected CONNECT attempts never create an active Transaction');
    $client->close if !$client->is_closed;
    $listener->close;
};

done_testing;
