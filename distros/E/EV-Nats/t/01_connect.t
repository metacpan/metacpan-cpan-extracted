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
    plan skip_all => "NATS server not available at $host:$port "
                   . "(set TEST_NATS_HOST/TEST_NATS_PORT)";
}
close $sock;

plan tests => 4;

my $connected = 0;
my $nats;

$nats = EV::Nats->new(
    host       => $host,
    port       => $port,
    on_error   => sub { diag "error: @_"; EV::break },
    on_connect => sub {
        $connected = 1;
        ok $nats->is_connected, 'is_connected after on_connect';
        ok defined($nats->server_info), 'server_info available';

        $nats->disconnect;
        EV::break;
    },
    on_disconnect => sub {
        pass 'on_disconnect fired';
    },
    connect_timeout => 5000,
);

EV::run;

ok $connected, 'connected to NATS';
