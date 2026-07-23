use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Memcached;

my $host = $ENV{TEST_MEMCACHED_HOST} || '127.0.0.1';
my $port = $ENV{TEST_MEMCACHED_PORT} || 11211;

my $sock = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1,
);
unless ($sock) {
    plan skip_all => "No memcached at $host:$port";
}
close $sock;

# quit() is an intentional disconnect: the server's response-then-close
# must fire on_disconnect but neither on_error nor auto-reconnect.
my @events;
my $mc = EV::Memcached->new(
    host          => $host,
    port          => $port,
    reconnect     => 1,
    reconnect_delay => 100,
    on_connect    => sub { push @events, 'on_connect' },
    on_disconnect => sub { push @events, 'on_disconnect' },
    on_error      => sub { push @events, "on_error($_[0])" },
);

my $once = EV::timer 0.3, 0, sub {
    $mc->quit(sub {
        my ($ok, $err) = @_;
        push @events, $err ? "quit err=$err" : 'quit cb';
    });
};
my $end = EV::timer 1.3, 0, sub { EV::break };
EV::run;

is_deeply(\@events, ['on_connect', 'quit cb', 'on_disconnect'],
    'quit: cb and on_disconnect fire, no on_error, no reconnect')
    or diag "events: @events";

done_testing;
