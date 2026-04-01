use strict;
use warnings;
use Test::More;
use EV;
use EV::Websockets;

# Test new features: ping/pong, peer_address, connections, max_message_size,
# server request headers, pause/resume_recv, send_pong

my $ctx = EV::Websockets::Context->new();
my $port = $ctx->listen(
    port             => 0,
    max_message_size => 256,
    on_connect => sub {
        my ($c, $headers) = @_;
        # Test: server gets request headers
        $main::server_headers = $headers;
        $main::server_peer    = $c->peer_address;
        $main::server_conn    = $c;
    },
    on_message => sub {
        my ($c, $data) = @_;
        $main::server_msg = $data;
        $c->send("reply:$data");
    },
    on_pong => sub {
        my ($c, $payload) = @_;
        $main::server_pong = $payload;
        # Signal client it's safe to close now
        $c->send("pong_ack");
    },
    on_close => sub {
        $main::server_close = 1;
        undef $main::server_conn;
        EV::break if $main::client_done;
    },
    on_error => sub {
        my ($c, $err) = @_;
        $main::server_error = $err;
    },
);

ok($port > 0, "listen() returned port $port");

# Track test progress
my $phase = 0;
our ($server_headers, $server_peer, $server_conn, $server_msg);
our ($server_pong, $server_close, $server_error);
my ($client_pong, $client_connected, $conns_during);
my %keep;

my $start = EV::timer(0.1, 0, sub {
    $keep{conn} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub {
            my ($c) = @_;
            $client_connected = 1;

            # Test: connections() accessor
            my @conns = $ctx->connections;
            $conns_during = scalar @conns;

            # Test: send_ping (server should auto-pong, triggering on_pong on client)
            $c->send_ping("latency");

            # Test: send a message
            $c->send("hello");
        },
        on_message => sub {
            my ($c, $data) = @_;
            if ($data eq 'reply:hello') {
                $c->send_pong("manual_pong");
            } elsif ($data eq 'pong_ack') {
                $c->close(1001, "test done");
            }
        },
        on_pong => sub {
            my ($c, $payload) = @_;
            $client_pong = $payload;
        },
        on_close => sub {
            delete $keep{conn};
            $main::client_done = 1;
            EV::break if $main::server_close;
            # Give server time to process close
            my $t; $t = EV::timer(0.5, 0, sub { undef $t; EV::break; });
        },
        on_error => sub {
            diag "Client error: $_[1]";
            delete $keep{conn};
            EV::break;
        },
    );
});

my $timeout = EV::timer(15, 0, sub { diag "Timeout!"; EV::break; });
EV::run;

# Assertions
ok($client_connected, "client connected");

# server request headers
ok(ref $server_headers eq 'HASH', "server on_connect received headers hashref");
like($server_headers->{Host} || '', qr/127\.0\.0\.1/, "server sees Host header");

# peer_address
like($server_peer || '', qr/127\.0\.0\.1/, "server peer_address is 127.0.0.1");

# connections accessor
ok($conns_during && $conns_during >= 2, "connections() returned >= 2 during active session (got $conns_during)");

# message echo
is($server_msg, "hello", "server received message");

# pong callbacks
is($client_pong, "latency", "client on_pong received ping payload back");
is($server_pong, "manual_pong", "server on_pong received client's send_pong");

# close
ok($server_close, "server saw close");

done_testing;
