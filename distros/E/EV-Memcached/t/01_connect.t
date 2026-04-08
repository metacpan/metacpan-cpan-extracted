use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Memcached;

my $host = $ENV{TEST_MEMCACHED_HOST} || '127.0.0.1';
my $port = $ENV{TEST_MEMCACHED_PORT} || 11211;

# Skip if no memcached server
my $sock = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => $port,
    Proto    => 'tcp',
    Timeout  => 1,
);
unless ($sock) {
    plan skip_all => "No memcached at $host:$port (set TEST_MEMCACHED_HOST/PORT)";
}
close $sock;

# Test module loads
ok(1, 'module loaded');

# Test constructor without connection
{
    my $mc = EV::Memcached->new(on_error => sub {});
    ok($mc, 'constructor without connection');
    ok(!$mc->is_connected, 'not connected initially');
}

# Test connection
{
    my $connected = 0;
    my $mc = EV::Memcached->new(
        host       => $host,
        port       => $port,
        on_error   => sub { diag "error: @_" },
        on_connect => sub { $connected = 1 },
    );

    my $t = EV::timer 5, 0, sub { EV::break };
    EV::run;

    ok($connected, 'connected to memcached');
    ok($mc->is_connected, 'is_connected returns true');

    # Test version
    my $version;
    $mc->version(sub {
        ($version, my $err) = @_;
        EV::break;
    });
    EV::run;

    ok($version, "server version: $version");

    # Disconnect
    my $disconnected = 0;
    $mc->on_disconnect(sub { $disconnected = 1 });
    $mc->disconnect;
    ok(!$mc->is_connected, 'disconnected');
    ok($disconnected, 'on_disconnect called');
}

done_testing;
