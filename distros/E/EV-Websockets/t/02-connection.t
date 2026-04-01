use strict;
use warnings;
use Test::More;
use EV;
use EV::Websockets;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::WebSocket::Server;

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

my $port = 12345 + int(rand(1000));
my $server = AnyEvent::WebSocket::Server->new;
my $cv = AnyEvent->condvar;

my %server_conns;
my $tcp_server = tcp_server undef, $port, sub {
    my ($fh, $host, $port) = @_;
    diag "Server: accepted connection from $host:$port";
    $server->establish($fh)->cb(sub {
        my $connection = eval { shift->recv };
        if($@) {
            diag "Server: error establishing connection: $@";
            return;
        }
        my $id = "$connection";
        $server_conns{$id} = $connection;
        diag "Server: WebSocket established ($id)";
        $connection->on(each_message => sub {
            my ($connection, $message) = @_;
            diag "Server: got message: " . $message->body;
            $connection->send($message->body);
        });
        $connection->on(finish => sub {
            diag "Server: connection finished ($id)";
            delete $server_conns{$id};
        });
    });
};

my $ctx = EV::Websockets::Context->new();
my $connected = 0;
my $message_received = '';
my $closed = 0;

my $conn = $ctx->connect(
    url => "ws://127.0.0.1:$port",
    on_connect => sub {
        my ($c) = @_;
        diag "Client: connected";
        $connected = 1;
        $c->send("Hello Server");
    },
    on_message => sub {
        my ($c, $data, $is_binary) = @_;
        diag "Client: got message: $data";
        $message_received = $data;
        $c->close(1000, "Done");
    },
    on_close => sub {
        my ($c, $code, $reason) = @_;
        diag "Client: closed: $code " . ($reason // "");
        $closed = 1;
        $cv->send;
    },
    on_error => sub {
        my ($c, $err) = @_;
        diag "Client: error: $err";
        $cv->send;
    },
);

my $timeout = EV::timer(10, 0, sub { diag "Timeout"; $cv->send });
$cv->recv;

ok($connected, 'Connected to server');
is($message_received, 'Hello Server', 'Received echoed message');
ok($closed, 'Connection closed');

done_testing;
