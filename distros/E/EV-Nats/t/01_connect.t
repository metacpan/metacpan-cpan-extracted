use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use NatsLive;
use EV;
use EV::Nats;

my ($host, $port) = nats_or_skip();

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
