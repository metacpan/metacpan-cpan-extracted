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

# Two subscribers in same queue group should split messages
my $nats;
$nats = EV::Nats->new(
    host       => $host,
    port       => $port,
    on_error   => sub { diag "error: @_"; EV::break },
    connect_timeout => 5000,
);

my $guard = EV::timer 10, 0, sub { fail 'timeout'; EV::break };

my ($count_a, $count_b) = (0, 0);
my $total_expected = 20;

my $ready; $ready = EV::timer 0.1, 0.1, sub {
    return unless $nats->is_connected;
    undef $ready;

    $nats->subscribe('qtest.>', sub { $count_a++ }, 'grp');
    $nats->subscribe('qtest.>', sub { $count_b++ }, 'grp');

    my $pub; $pub = EV::timer 0.1, 0, sub {
        undef $pub;
        for (1 .. $total_expected) {
            $nats->publish('qtest.x', 'data');
        }

        my $check; $check = EV::timer 0.5, 0, sub {
            undef $check;
            my $total = $count_a + $count_b;
            is $total, $total_expected, "total messages received = $total_expected";
            ok $count_a > 0, "worker A got messages ($count_a)";
            ok $count_b > 0, "worker B got messages ($count_b)";
            $nats->disconnect;
            EV::break;
        };
    };
};

EV::run;
