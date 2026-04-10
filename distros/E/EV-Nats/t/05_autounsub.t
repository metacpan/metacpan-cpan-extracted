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

my $nats;
$nats = EV::Nats->new(
    host       => $host,
    port       => $port,
    on_error   => sub { diag "error: @_"; EV::break },
    connect_timeout => 5000,
);

my $guard = EV::timer 10, 0, sub { fail 'timeout'; EV::break };

my $received = 0;

my $ready; $ready = EV::timer 0.1, 0.1, sub {
    return unless $nats->is_connected;
    undef $ready;

    my $sid = $nats->subscribe('autounsub.test', sub {
        my ($subject, $payload) = @_;
        $received++;
    });

    # auto-unsub after 3 messages
    $nats->unsubscribe($sid, 3);

    my $pub; $pub = EV::timer 0.1, 0, sub {
        undef $pub;
        # send 10 messages, should only receive 3
        for (1 .. 10) {
            $nats->publish('autounsub.test', "msg-$_");
        }

        my $check; $check = EV::timer 0.5, 0, sub {
            undef $check;
            is $received, 3, 'received exactly 3 messages with auto-unsub';
            ok $received <= 3, 'did not exceed max_msgs';
            $nats->disconnect;
            EV::break;
        };
    };
};

EV::run;
