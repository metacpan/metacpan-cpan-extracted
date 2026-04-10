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

my $n = 10000;

my $nats;
$nats = EV::Nats->new(
    host       => $host,
    port       => $port,
    on_error   => sub { diag "error: @_"; EV::break },
    connect_timeout => 5000,
);

my $guard = EV::timer 30, 0, sub { fail 'timeout'; EV::break };

my $ready; $ready = EV::timer 0.1, 0.1, sub {
    return unless $nats->is_connected;
    undef $ready;

    # Stress: rapid-fire pub/sub
    my $received = 0;
    $nats->subscribe('stress.test', sub {
        $received++;
        if ($received >= $n) {
            is $received, $n, "received all $n messages";
            pass 'no crashes during stress';
            $nats->disconnect;
            EV::break;
        }
    });

    my $pub; $pub = EV::timer 0.05, 0, sub {
        undef $pub;
        for (1 .. $n) {
            $nats->publish('stress.test', "msg-$_");
        }
    };
};

EV::run;
