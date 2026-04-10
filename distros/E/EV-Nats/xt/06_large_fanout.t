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

my $n_subs = 100;
my $n_msgs = 100;
my $guard = EV::timer 30, 0, sub { fail 'timeout'; EV::break };

my $nats;
$nats = EV::Nats->new(
    host       => $host,
    port       => $port,
    on_error   => sub { diag "error: @_"; EV::break },
    on_connect => sub {
        # Create many subscriptions on different subjects
        my @counts;
        for my $i (0 .. $n_subs - 1) {
            $counts[$i] = 0;
            $nats->subscribe("fanout.sub.$i", sub { $counts[$i]++ });
        }

        is $nats->subscription_count, $n_subs, "$n_subs subscriptions created";

        my $t; $t = EV::timer 0.1, 0, sub {
            undef $t;

            # Publish to all subjects
            $nats->batch(sub {
                for my $m (1 .. $n_msgs) {
                    for my $i (0 .. $n_subs - 1) {
                        $nats->publish("fanout.sub.$i", "m$m");
                    }
                }
            });

            my $c; $c = EV::timer 2, 0, sub {
                undef $c;
                my $total = 0;
                $total += $_ for @counts;
                is $total, $n_subs * $n_msgs,
                    "total received: $total (expected " . ($n_subs * $n_msgs) . ")";
                $nats->disconnect;
                EV::break;
            };
        };
    },
);

EV::run;
