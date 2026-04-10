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

plan tests => 4;

my $guard = EV::timer 10, 0, sub { fail 'timeout'; EV::break };

my $nats;
$nats = EV::Nats->new(
    host       => $host,
    port       => $port,
    on_error   => sub { diag "error: @_" },
    connect_timeout => 5000,
);

my $ready; $ready = EV::timer 0.1, 0.1, sub {
    return unless $nats->is_connected;
    undef $ready;

    # max_payload is set from server INFO (typically 1MB)
    my $max = $nats->max_payload;
    ok $max > 0, "max_payload from server: $max";

    # Publish at exactly max_payload should succeed
    my $received_max = 0;
    $nats->subscribe('maxpay.ok', sub { $received_max++ });
    my $t; $t = EV::timer 0.1, 0, sub {
        undef $t;
        eval { $nats->publish('maxpay.ok', 'x' x ($max - 1)) };
        ok !$@, 'publish at max_payload-1 succeeds';

        # Publish over max_payload should croak
        eval { $nats->publish('maxpay.over', 'x' x ($max + 1)) };
        like $@, qr/max_payload/, 'publish over max_payload croaks';

        # Verify connection still works after croak
        $nats->subscribe('maxpay.after', sub {
            pass 'connection still alive after max_payload croak';
            $nats->disconnect;
            EV::break;
        });
        my $p; $p = EV::timer 0.1, 0, sub {
            undef $p;
            $nats->publish('maxpay.after', 'alive');
        };
    };
};

EV::run;
