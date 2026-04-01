use strict;
use warnings;
use Test::More;
use EV;
use EV::Websockets;

# Test multiple simultaneous clients + broadcast via connections()

my $ctx = EV::Websockets::Context->new();
my (%keep, @srv_conns, $broadcast_count);
my (%client_got);

my $port = $ctx->listen(
    port => 0,
    on_connect => sub {
        my ($c) = @_;
        push @srv_conns, $c;
        # When second client connects, broadcast to all
        if (@srv_conns == 2) {
            for my $conn ($ctx->connections) {
                $conn->send("broadcast");
                $broadcast_count++;
            }
        }
    },
    on_close => sub {
        @srv_conns = grep { $_->is_connected } @srv_conns;
    },
);

ok($port > 0, "listening on port $port");

my $closed = 0;
my $make_client = sub {
    my ($id) = @_;
    $keep{$id} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_message => sub {
            my ($c, $data) = @_;
            $client_got{$id} = $data;
            $c->close(1000);
        },
        on_close => sub {
            delete $keep{$id};
            $closed++;
            if ($closed >= 2) {
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
            }
        },
        on_error => sub { delete $keep{$id}; EV::break },
    );
};

# Stagger connections slightly
my $t1 = EV::timer(0.1, 0, sub { $make_client->("A") });
my $t2 = EV::timer(0.2, 0, sub { $make_client->("B") });

my $to = EV::timer(15, 0, sub { diag "Timeout"; EV::break });
EV::run;

# connections() returns all connected conns (client + server sides)
ok($broadcast_count >= 2, "broadcast sent to >= 2 connections (got $broadcast_count)");
is($client_got{A}, "broadcast", "client A received broadcast");
is($client_got{B}, "broadcast", "client B received broadcast");

done_testing;
