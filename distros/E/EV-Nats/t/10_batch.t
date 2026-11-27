use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use NatsLive;
use EV;
use EV::Nats;

my ($host, $port) = nats_or_skip();

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
