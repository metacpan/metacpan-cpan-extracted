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

my $drained = 0;
my $disconnected = 0;

my $nats;
$nats = EV::Nats->new(
    host       => $host,
    port       => $port,
    on_error   => sub { diag "error: @_"; EV::break },
    on_disconnect => sub { $disconnected = 1 },
    connect_timeout => 5000,
);

my $guard = EV::timer 10, 0, sub { fail 'timeout'; EV::break };

my $ready; $ready = EV::timer 0.1, 0.1, sub {
    return unless $nats->is_connected;
    undef $ready;

    $nats->subscribe('drain.test', sub {});

    my $t; $t = EV::timer 0.1, 0, sub {
        undef $t;
        $nats->drain(sub {
            $drained = 1;
            pass 'drain callback fired';
        });

        my $check; $check = EV::timer 1, 0, sub {
            undef $check;
            ok $drained, 'drain completed';
            ok $disconnected, 'disconnected after drain';
            EV::break;
        };
    };
};

EV::run;
