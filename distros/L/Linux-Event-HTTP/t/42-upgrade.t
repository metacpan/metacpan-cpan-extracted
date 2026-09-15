use v5.36;
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);

use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::HTTP::Server::Connection;
use Linux::Event::HTTP::Server;

sub run_client ($loop, $server, $wire, $state, $done) {
    my $guard = Linux::Event::Kernel::Timer->new(
        loop  => $loop,
        after => 2,
        on_timer => sub ($timer) {
            diag('Upgrade wire before timeout: ' . $state->{wire});
            die "HTTP Upgrade integration test timed out\n";
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
            die "HTTP Upgrade client failed: $error\n";
        },
    );

    $loop->run;
    return;
}

{
    package T::UpgradedProtocol;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Scalar::Util qw(refaddr);

    sub on_data ($self, $bytes) {
        my $state = $self->data;
        $state->{target_hits}++;
        $state->{target_class} = ref($self);
        $state->{same_object} = refaddr($self) == $state->{http_ref} ? 1 : 0;
        $state->{target_input} .= $bytes;
        $self->write("TARGET:$bytes");
    }
}

{
    package T::UpgradeHTTP;
    use parent 'Linux::Event::HTTP::Server::Connection';
    use Scalar::Util qw(refaddr);

    sub on_request ($self, $req, $res) {
        my $state = $self->data;
        my $transaction = $self->transaction;
        $state->{transaction} = $transaction;
        $state->{http_ref} = refaddr($self);
        $state->{request_class} = ref($req);
        $res->header('Upgrade', 'test-proto');
        $res->header('X-Handshake', 'ok');
        $transaction->upgrade('T::UpgradedProtocol');
        $state->{pending_in_request} = $transaction->is_upgrading ? 1 : 0;
        $state->{started_in_request}
            = $transaction->is_response_started ? 1 : 0;
    }

    sub on_request_end ($self, $req, $res) {
        my $state = $self->data;
        my $transaction = $self->transaction;
        $state->{request_end_hits}++;
        $state->{pending_at_request_end}
            = $transaction->is_upgrading ? 1 : 0;
        $state->{complete_at_request_end} = $res->is_complete ? 1 : 0;
    }
}

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
    connection_class => 'T::UpgradeHTTP',
);

run_client(
    $loop,
    $server,
    "GET /switch HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Connection: keep-alive, Upgrade\r\n" .
        "Upgrade: test-proto\r\n" .
        "\r\n" .
        "PING",
    $state,
    qr/TARGET:PING\z/,
);

ok($state->{pending_in_request},
    'Upgrade is pending while on_request remains on the stack');
ok(!$state->{started_in_request},
    '101 response output is not started inside on_request');
is($state->{request_end_hits}, 1,
    'normal on_request_end lifecycle runs before handoff');
ok($state->{pending_at_request_end},
    'handoff remains pending during on_request_end');
ok(!$state->{complete_at_request_end},
    'Response message is not complete until switching response commits');
ok($state->{transaction}->is_complete,
    'Upgrade Transaction completes before protocol handoff');
ok(!$state->{transaction}->is_upgrading,
    'Upgrade pending state clears after successful handoff');
is($state->{target_hits}, 1,
    'target protocol receives preserved post-HTTP input');
is($state->{target_input}, 'PING',
    'bytes following request head in same TCP write survive handoff');
is($state->{target_class}, 'T::UpgradedProtocol',
    'same live stream object is reblessed to target protocol class');
ok($state->{same_object},
    'protocol handoff retains object identity');
is($state->{request_class}, 'Linux::Event::HTTP::Request',
    'HTTP request is parsed normally before handoff');
is(
    $state->{wire},
    "HTTP/1.1 101 Switching Protocols\r\n" .
        "Upgrade: test-proto\r\n" .
        "X-Handshake: ok\r\n" .
        "Connection: Upgrade\r\n" .
        "\r\n" .
        "TARGET:PING",
    '101 switching response is queued before target protocol output',
);

{
    package T::BadUpgradeHTTP;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub on_request ($self, $req, $res) {
        $res->header('Upgrade', 'other-proto');
        $self->transaction->upgrade('T::UpgradedProtocol');
    }
}

$loop = Linux::Event::Loop->new;
my $bad = { wire => '' };
$server = Linux::Event::HTTP::Server->new(
    loop             => $loop,
    host             => '127.0.0.1',
    port             => 0,
    data             => $bad,
    connection_class => 'T::BadUpgradeHTTP',
);

run_client(
    $loop,
    $server,
    "GET /bad HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Connection: Upgrade\r\n" .
        "Upgrade: test-proto\r\n" .
        "\r\n",
    $bad,
    qr/\r\n\r\n\z/,
);

like(
    $bad->{wire},
    qr/\AHTTP\/1\.1 500 Internal Server Error\r\n/s,
    'selecting a protocol not offered by the request fails before 101',
);
unlike($bad->{wire}, qr/101 Switching Protocols/,
    'invalid Upgrade never emits a switching response');

{
    package T::BodyUpgradeHTTP;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub on_request ($self, $req, $res) {
        $res->header('Upgrade', 'test-proto');
        $self->transaction->upgrade('T::UpgradedProtocol');
    }
}

$loop = Linux::Event::Loop->new;
my $body = { wire => '' };
$server = Linux::Event::HTTP::Server->new(
    loop             => $loop,
    host             => '127.0.0.1',
    port             => 0,
    data             => $body,
    connection_class => 'T::BodyUpgradeHTTP',
);

run_client(
    $loop,
    $server,
    "POST /bad-body HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Connection: Upgrade\r\n" .
        "Upgrade: test-proto\r\n" .
        "Content-Length: 1\r\n" .
        "\r\n" .
        "x",
    $body,
    qr/\r\n\r\n\z/,
);

like(
    $body->{wire},
    qr/\AHTTP\/1\.1 500 Internal Server Error\r\n/s,
    'body-bearing Upgrade is rejected before protocol switch',
);
unlike($body->{wire}, qr/101 Switching Protocols/,
    'body-bearing request never enters target protocol');

done_testing;
