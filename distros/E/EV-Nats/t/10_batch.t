use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Nats;

my $host = $ENV{TEST_NATS_HOST} || '127.0.0.1';
my $port = $ENV{TEST_NATS_PORT} || 4222;

my $sock = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => $port,
    Timeout  => 1,
);
unless ($sock) {
    plan skip_all => "NATS server not available at $host:$port";
}
close $sock;

plan tests => 2;

my $n = 100;
my $nats;
$nats = EV::Nats->new(
    host       => $host,
    port       => $port,
    on_error   => sub { diag "error: @_"; EV::break },
    connect_timeout => 5000,
);

my $guard = EV::timer 10, 0, sub { fail 'timeout'; EV::break };

my $ready; $ready = EV::timer 0.1, 0.1, sub {
    return unless $nats->is_connected;
    undef $ready;

    my $received = 0;
    $nats->subscribe('batch.test', sub {
        $received++;
        if ($received >= $n) {
            is $received, $n, "received all $n batched messages";
            my %stats = $nats->stats;
            ok $stats{msgs_out} >= $n, "stats tracked $stats{msgs_out} msgs_out";
            $nats->disconnect;
            EV::break;
        }
    });

    my $t; $t = EV::timer 0.1, 0, sub {
        undef $t;
        $nats->batch(sub {
            $nats->publish("batch.test", "msg-$_") for 1 .. $n;
        });
    };
};

EV::run;
