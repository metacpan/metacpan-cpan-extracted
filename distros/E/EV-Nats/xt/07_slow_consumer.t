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

my $guard = EV::timer 15, 0, sub { fail 'timeout'; EV::break };

my $slow_triggered = 0;
my $slow_bytes = 0;

my $nats;
$nats = EV::Nats->new(
    host                => $host,
    port                => $port,
    slow_consumer_bytes => 4096,
    on_slow_consumer    => sub {
        $slow_bytes = $_[0] unless $slow_triggered;
        $slow_triggered++;
    },
    on_error => sub { diag "error: @_" },
    connect_timeout => 5000,
);

my $ready; $ready = EV::timer 0.1, 0.1, sub {
    return unless $nats->is_connected;
    undef $ready;

    # Subscribe but process slowly (accumulate in wbuf via rapid publish)
    $nats->subscribe('slow.test', sub {});

    # Flood: publish lots of large messages rapidly
    $nats->batch(sub {
        $nats->publish('slow.test', 'x' x 1024) for 1 .. 200;
    });

    my $check; $check = EV::timer 1, 0, sub {
        undef $check;
        ok $slow_triggered > 0, "slow consumer callback fired ($slow_triggered times)";
        ok $slow_bytes > 4096, "reported $slow_bytes bytes pending (threshold 4096)";
        $nats->disconnect;
        EV::break;
    };
};

EV::run;
