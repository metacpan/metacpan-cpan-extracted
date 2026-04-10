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

plan tests => 3;

my $n = 1000;
my $guard = EV::timer 30, 0, sub { fail 'timeout'; EV::break };

my $nats;
$nats = EV::Nats->new(
    host       => $host,
    port       => $port,
    on_error   => sub { diag "error: @_"; EV::break },
    on_connect => sub {
        # Echo service
        $nats->subscribe('conc.echo', sub {
            my ($s, $p, $r) = @_;
            $nats->publish($r, $p) if $r;
        });

        my $t; $t = EV::timer 0.1, 0, sub {
            undef $t;

            # Fire N concurrent requests
            my $completed = 0;
            my $errors    = 0;
            my $mismatches = 0;

            for my $i (1 .. $n) {
                $nats->request("conc.echo", "req-$i", sub {
                    my ($resp, $err) = @_;
                    if ($err) {
                        $errors++;
                    } elsif ($resp ne "req-$i") {
                        $mismatches++;
                    }
                    $completed++;
                    if ($completed >= $n) {
                        is $completed, $n, "all $n requests completed";
                        is $errors, 0, 'no errors';
                        is $mismatches, 0, 'all responses matched request';
                        $nats->disconnect;
                        EV::break;
                    }
                }, 10000);
            }
        };
    },
);

EV::run;
