use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use NatsLive;
use EV;
use EV::Nats;

my ($host, $port) = nats_or_skip();

plan tests => 3;

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

    # Test various payload sizes
    my @sizes = (0, 1, 65536);
    my $done = 0;

    for my $sz (@sizes) {
        my $data = 'A' x $sz;
        my $subj = "large.$sz";

        $nats->subscribe($subj, sub {
            my ($subject, $payload) = @_;
            is length($payload), $sz, "received ${sz}B payload";
            $done++;
            if ($done >= scalar @sizes) {
                $nats->disconnect;
                EV::break;
            }
        });
    }

    my $pub; $pub = EV::timer 0.1, 0, sub {
        undef $pub;
        for my $sz (@sizes) {
            $nats->publish("large.$sz", 'A' x $sz);
        }
    };
};

EV::run;
