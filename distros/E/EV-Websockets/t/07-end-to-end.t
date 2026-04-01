use strict;
use warnings;
use Test::More;
use EV;
use EV::Websockets;

# Pure EV::Websockets E2E test (Native Client & Native Listener)

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

my $ctx = EV::Websockets::Context->new();

my %results = (
    server_received => '',
    client_received => '',
    done => 0,
);

my %keep_alive;

# 1. Native Listener (port 0 = OS-assigned)
my $port = $ctx->listen(
    port => 0,
    on_connect => sub {
        my ($c) = @_;
        diag "Server: WebSocket established";
        $keep_alive{server_conn} = $c;
    },
    on_message => sub {
        my ($c, $data) = @_;
        $results{server_received} = $data;
        diag "Server: Received '$data', echoing...";
        $c->send("Echo: $data");
    },
    on_close => sub {
        diag "Server: Connection closed";
        delete $keep_alive{server_conn};
    }
);

diag "Server: listening on port $port";

# 2. Native Client
my $timer = EV::timer(0.1, 0, sub {
    diag "Client: initiating connection...";
    $keep_alive{client_conn} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub {
            my ($c) = @_;
            diag "Client: connected, sending greeting";
            $c->send("Hello Native");
        },
        on_message => sub {
            my ($c, $data) = @_;
            $results{client_received} = $data;
            diag "Client: received '$data'";
            $results{done} = 1;
            $c->close(1000, "Done");
        },
        on_close => sub {
            diag "Client: closed";
            delete $keep_alive{client_conn};
            EV::break;
        },
        on_error => sub {
            diag "Client Error: $_[1]";
            delete $keep_alive{client_conn};
            EV::break;
        }
    );
    diag "Client: Stored conn=" . $keep_alive{client_conn};
});

# 3. Execution
my $timeout = EV::timer(10, 0, sub { diag "Test timed out"; EV::break; });

diag "Entering loop";
EV::run;

is($results{server_received}, "Hello Native", "Server received client message");
is($results{client_received}, "Echo: Hello Native", "Client received server response");
ok($results{done}, "E2E handshake and data exchange successful");

done_testing;
