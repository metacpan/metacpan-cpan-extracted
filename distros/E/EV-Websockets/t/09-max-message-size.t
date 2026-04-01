use strict;
use warnings;
use Test::More;
use EV;
use EV::Websockets;

# Test max_message_size enforcement: server rejects oversized messages

my $ctx = EV::Websockets::Context->new();
my $port = $ctx->listen(
    port             => 0,
    max_message_size => 64,
    on_connect => sub {
        $main::srv_conn = $_[0];
    },
    on_message => sub {
        my ($c, $data) = @_;
        $main::srv_msg = $data;
        $c->send("ok");
    },
    on_error => sub {
        my ($c, $err) = @_;
        $main::srv_error = $err;
    },
    on_close => sub {
        $main::srv_close = 1;
    },
);

ok($port > 0, "server listening on port $port");

our ($srv_conn, $srv_msg, $srv_error, $srv_close);
my ($got_reply, $got_error, $got_close);
my %keep;

my $start = EV::timer(0.3, 0, sub {
    $keep{c} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub {
            my ($c) = @_;
            # Send a small message first (should work)
            $c->send("small");
        },
        on_message => sub {
            my ($c, $data) = @_;
            if ($data eq 'ok') {
                $got_reply = 1;
                # Now send an oversized message (> 64 bytes)
                $c->send("x" x 128);
            }
        },
        on_error => sub {
            my ($c, $err) = @_;
            $got_error = $err;
        },
        on_close => sub {
            $got_close = 1;
            delete $keep{c};
            EV::break;
        },
    );
});

my $timeout = EV::timer(10, 0, sub { diag "Timeout!"; EV::break; });
EV::run;

ok($got_reply, "small message accepted");
like($srv_error || '', qr/max_message_size/, "server error mentions max_message_size");
ok($got_close || $srv_close, "connection closed after oversized message");

done_testing;
