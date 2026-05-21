use strict;
use warnings;
use Test::More;
use EV;
use EV::Nats;

plan skip_all => 'EV::Nats built without TLS' unless EV::Nats::HAS_TLS();
plan skip_all => 'set NATS_TLS=1 and NATS_CA_FILE to enable'
    unless $ENV{NATS_TLS};

my $host    = $ENV{TEST_NATS_HOST} || '127.0.0.1';
my $port    = $ENV{TEST_NATS_PORT} || 4222;
my $ca_file = $ENV{NATS_CA_FILE};

plan tests => 4;

# 1. Connect with proper CA -> success
{
    my $connected = 0;
    my $err;
    my $nats = EV::Nats->new(
        host        => $host,
        port        => $port,
        tls         => 1,
        tls_ca_file => $ca_file,
        on_connect  => sub { $connected = 1; EV::break },
        on_error    => sub { $err = $_[0]; EV::break },
    );
    EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok $connected, 'TLS connect with CA succeeded' or diag "err: $err";

    if ($connected) {
        my $got;
        $nats->subscribe('tls.echo', sub { $got = $_[1]; EV::break });
        $nats->publish('tls.echo', 'hello-tls');
        EV::timer(2, 0, sub { EV::break });
        EV::run;
        is $got, 'hello-tls', 'TLS pub/sub roundtrip works';
    } else {
        fail 'TLS pub/sub roundtrip skipped (no connection)';
    }

    $nats->disconnect;
}

# 2. Hostname verification: connect to 127.0.0.1 cert against IP -> should work
#    because cert SAN includes the IP. (Sanity check that fix #1 doesn't over-reject.)
{
    my $connected = 0;
    my $err;
    my $nats = EV::Nats->new(
        host        => '127.0.0.1',
        port        => $port,
        tls         => 1,
        tls_ca_file => $ca_file,
        on_connect  => sub { $connected = 1; EV::break },
        on_error    => sub { $err = $_[0]; EV::break },
    );
    EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok $connected, 'TLS hostname verification accepts SAN match'
        or diag "err: $err";
    $nats->disconnect if $connected;
}

# 3. tls_skip_verify bypasses both chain and hostname checks
{
    my $connected = 0;
    my $nats = EV::Nats->new(
        host             => $host,
        port             => $port,
        tls              => 1,
        tls_skip_verify  => 1,
        on_connect       => sub { $connected = 1; EV::break },
        on_error         => sub { EV::break },
    );
    EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok $connected, 'tls_skip_verify=1 connects without CA';
    $nats->disconnect if $connected;
}
