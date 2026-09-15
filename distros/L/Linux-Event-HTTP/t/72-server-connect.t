use v5.36;
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);

use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::HTTP::Server;
use Linux::Event::HTTP::Server::Connection;

sub run_client ($loop, $server, $wire, $state, $done) {
    my $guard = Linux::Event::Kernel::Timer->new(
        loop  => $loop,
        after => 2,
        on_timer => sub ($timer) {
            diag('CONNECT wire before timeout: ' . ($state->{wire} // ''));
            die "server CONNECT integration test timed out\n";
        },
    );

    Linux::Event::IO::Sock::Stream->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $server->port,
        on_ready => sub ($stream) {
            $stream->write($wire);
        },
        on_data => sub ($stream, $bytes) {
            $state->{wire} .= $bytes;
            if ($state->{wire} =~ $done) {
                $guard->cancel;
                $stream->close;
                $server->close;
                $loop->stop;
            }
        },
        on_eof => sub ($stream) {
            $guard->cancel;
            $stream->close;
            $server->close;
            $loop->stop;
        },
        on_error => sub ($stream, $error) {
            die "server CONNECT client failed: $error\n";
        },
    );

    $loop->run;
    return;
}

{
    package T::ServerTunnelProtocol;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Scalar::Util qw(refaddr);

    sub on_data ($self, $bytes) {
        my $state = $self->data;
        $state->{target_hits}++;
        $state->{target_input} .= $bytes;
        $state->{target_class} = ref($self);
        $state->{same_object} = refaddr($self) == $state->{http_ref} ? 1 : 0;
        $self->write("TUNNEL:$bytes");
    }
}

{
    package T::ConnectHTTP;
    use parent 'Linux::Event::HTTP::Server::Connection';
    use Scalar::Util qw(refaddr);

    sub on_request ($self, $req, $res) {
        my $state = $self->data;
        my $transaction = $self->transaction;
        $state->{transaction} = $transaction;
        $state->{http_ref} = refaddr($self);
        $state->{method} = $req->method;
        $state->{target} = $req->target;
        $state->{host} = $req->header('Host');
        $res->header('X-Proxy', 'ok');
        $transaction->tunnel('T::ServerTunnelProtocol');
        $state->{pending_in_request} = $transaction->is_tunneling ? 1 : 0;
        $state->{started_in_request}
            = $transaction->is_response_started ? 1 : 0;
        $state->{response_complete_in_request}
            = $res->is_complete ? 1 : 0;
    }

    sub on_request_end ($self, $req, $res) {
        my $state = $self->data;
        my $transaction = $self->transaction;
        $state->{request_end_hits}++;
        $state->{pending_at_request_end}
            = $transaction->is_tunneling ? 1 : 0;
        $state->{response_complete_at_request_end}
            = $res->is_complete ? 1 : 0;
    }
}

subtest 'successful CONNECT hands the same live stream to the tunnel protocol' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = {
        wire => '',
        target_hits => 0,
        target_input => '',
        request_end_hits => 0,
    };

    my $server = Linux::Event::HTTP::Server->new(
        loop             => $loop,
        host             => '127.0.0.1',
        port             => 0,
        data             => $state,
        connection_class => 'T::ConnectHTTP',
    );

    run_client(
        $loop,
        $server,
        "CONNECT example.test:443 HTTP/1.1\r\n" .
            "Host: example.test:443\r\n" .
            "\r\n" .
            "PING",
        $state,
        qr/TUNNEL:PING\z/,
    );

    is($state->{method}, 'CONNECT', 'CONNECT request reaches ordinary on_request');
    is($state->{target}, 'example.test:443', 'authority-form target is preserved');
    is($state->{host}, 'example.test:443', 'matching Host remains available');
    ok($state->{pending_in_request}, 'tunnel handoff is pending inside on_request');
    ok(!$state->{started_in_request}, '2xx response is not written inside on_request');
    ok(!$state->{response_complete_in_request},
        'Response does not complete until tunnel handoff commits');
    is($state->{request_end_hits}, 1,
        'normal on_request_end lifecycle runs before tunnel handoff');
    ok($state->{pending_at_request_end},
        'tunnel remains pending during on_request_end');
    ok(!$state->{response_complete_at_request_end},
        'Response remains incomplete during on_request_end');
    ok($state->{transaction}->is_complete,
        'CONNECT Transaction completes before target protocol owns the stream');
    ok(!$state->{transaction}->is_tunneling,
        'tunnel pending state clears after successful handoff');
    is($state->{target_hits}, 1,
        'target protocol receives bytes already read after CONNECT head');
    is($state->{target_input}, 'PING',
        'same-read post-CONNECT bytes become tunnel input');
    is($state->{target_class}, 'T::ServerTunnelProtocol',
        'same live object is transitioned to the target protocol class');
    ok($state->{same_object}, 'CONNECT tunnel handoff retains object identity');
    is(
        $state->{wire},
        "HTTP/1.1 200 OK\r\n" .
            "X-Proxy: ok\r\n" .
            "\r\n" .
            "TUNNEL:PING",
        'successful CONNECT response head is queued before target protocol output',
    );
    unlike($state->{wire}, qr/Content-Length:/i,
        'successful CONNECT response does not gain Content-Length');
    unlike($state->{wire}, qr/Transfer-Encoding:/i,
        'successful CONNECT response does not gain Transfer-Encoding');
};

{
    package T::RejectConnectHTTP;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub on_request ($self, $req, $res) {
        if ($req->method eq 'CONNECT') {
            $res->status(407);
            $res->header('Proxy-Authenticate', 'Basic realm="proxy"');
            $res->body('nope');
            return;
        }

        $res->body('OK');
    }
}

subtest 'rejected CONNECT remains ordinary persistent HTTP' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = { wire => '' };
    my $server = Linux::Event::HTTP::Server->new(
        loop             => $loop,
        host             => '127.0.0.1',
        port             => 0,
        data             => $state,
        connection_class => 'T::RejectConnectHTTP',
    );

    run_client(
        $loop,
        $server,
        "CONNECT example.test:443 HTTP/1.1\r\n" .
            "Host: example.test:443\r\n\r\n" .
            "GET /after HTTP/1.1\r\n" .
            "Host: example.test\r\n\r\n",
        $state,
        qr/\r\n\r\nOK\z/,
    );

    like($state->{wire}, qr/\AHTTP\/1\.1 407 [^\r\n]*\r\n/s,
        'application can reject CONNECT with an ordinary non-2xx response');
    like($state->{wire}, qr/Proxy-Authenticate: Basic realm="proxy"\r\n/i,
        'ordinary rejection headers are serialized normally');
    like($state->{wire}, qr/Content-Length: 4\r\n\r\nnopeHTTP\/1\.1 200 OK\r\n/s,
        'rejected CONNECT body completes before the next pipelined HTTP response');
    like($state->{wire}, qr/HTTP\/1\.1 200 OK\r\nContent-Length: 2\r\n\r\nOK\z/s,
        'same server connection remains HTTP after rejected CONNECT');
};

{
    package T::InvalidConnectHTTP;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub on_request ($self, $req, $res) {
        my $case = $self->data->{case};
        $res->header('Content-Length', '0') if $case eq 'response-length';
        $res->header('Transfer-Encoding', 'chunked') if $case eq 'response-transfer';
        $res->header('Connection', 'close') if $case eq 'response-close';
        $res->status(407) if $case eq 'response-status';
        $res->body('') if $case eq 'response-body';
        $self->transaction->tunnel('T::ServerTunnelProtocol');
    }
}

sub failure_case ($name, $wire, $case) {
    my $loop = Linux::Event::Loop->new;
    my $state = { wire => '', case => $case };
    my $server = Linux::Event::HTTP::Server->new(
        loop             => $loop,
        host             => '127.0.0.1',
        port             => 0,
        data             => $state,
        connection_class => 'T::InvalidConnectHTTP',
    );

    run_client($loop, $server, $wire, $state, qr/\r\n\r\n\z/);
    like($state->{wire}, qr/\AHTTP\/1\.[01] 500 Internal Server Error\r\n/s,
        "$name fails before successful tunnel response");
    unlike($state->{wire}, qr/\AHTTP\/1\.[01] 2[0-9][0-9] /,
        "$name never emits a 2xx CONNECT response");
}

subtest 'invalid tunnel attempts fail before handoff' => sub {
    failure_case(
        'non-CONNECT method',
        "GET / HTTP/1.1\r\nHost: example.test\r\n\r\n",
        'request',
    );
    failure_case(
        'non-authority target',
        "CONNECT /bad HTTP/1.1\r\nHost: example.test:443\r\n\r\n",
        'request',
    );
    failure_case(
        'Host mismatch',
        "CONNECT example.test:443 HTTP/1.1\r\nHost: other.test:443\r\n\r\n",
        'request',
    );
    failure_case(
        'Content-Length field presence',
        "CONNECT example.test:443 HTTP/1.1\r\n" .
            "Host: example.test:443\r\nContent-Length: 0\r\n\r\n",
        'request',
    );
    failure_case(
        'Transfer-Encoding field presence',
        "CONNECT example.test:443 HTTP/1.1\r\n" .
            "Host: example.test:443\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n\r\n",
        'request',
    );
    failure_case(
        'HTTP/1.0 CONNECT',
        "CONNECT example.test:443 HTTP/1.0\r\nHost: example.test:443\r\n\r\n",
        'request',
    );
    failure_case(
        'successful response Content-Length',
        "CONNECT example.test:443 HTTP/1.1\r\nHost: example.test:443\r\n\r\n",
        'response-length',
    );
    failure_case(
        'successful response Transfer-Encoding',
        "CONNECT example.test:443 HTTP/1.1\r\nHost: example.test:443\r\n\r\n",
        'response-transfer',
    );
    failure_case(
        'successful response Connection close',
        "CONNECT example.test:443 HTTP/1.1\r\nHost: example.test:443\r\n\r\n",
        'response-close',
    );
    failure_case(
        'non-2xx response status',
        "CONNECT example.test:443 HTTP/1.1\r\nHost: example.test:443\r\n\r\n",
        'response-status',
    );
    failure_case(
        'successful response scalar body',
        "CONNECT example.test:443 HTTP/1.1\r\nHost: example.test:443\r\n\r\n",
        'response-body',
    );
};

done_testing;
