# getaddrinfo fallback: only the FIRST resolved address used to be
# tried, so host => 'localhost' on a dual-stack box (localhost -> ::1
# first) could never reach a gearmand bound to 127.0.0.1. Bind a
# listener on 127.0.0.1 ONLY and connect by name; the client must
# walk the candidate list until one connects.
#
# Proves nothing on single-stack hosts, so skip unless localhost
# actually resolves to something other than 127.0.0.1 first.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Socket qw(getaddrinfo SOCK_STREAM unpack_sockaddr_in inet_ntoa);
use EV;
use EV::Gearman;

my ($gai_err, @res) = getaddrinfo('localhost', 14730, { socktype => SOCK_STREAM });
plan skip_all => "getaddrinfo(localhost) failed: $gai_err" if $gai_err;
plan skip_all => 'localhost returned no addresses' unless @res;

my $first_is_v4_loopback = eval {
    my (undef, $addr) = unpack_sockaddr_in($res[0]{addr});
    inet_ntoa($addr) eq '127.0.0.1';
};
plan skip_all => 'localhost resolves to 127.0.0.1 first; fallback untestable here'
    if $first_is_v4_loopback;

my $srv = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1,
) or plan skip_all => "cannot bind 127.0.0.1 listener: $!";
my $port = $srv->sockport;

my ($connected, $err);
my $g = EV::Gearman->new(
    host => 'localhost', port => $port,
    on_connect => sub { $connected = 1; EV::break },
    on_error   => sub { $err = $_[0]; EV::break },
);
my $guard = EV::timer 5, 0, sub { fail 'connect timeout'; EV::break };
EV::run;

is $err, undef, 'no connect error';
ok $connected, 'connected to 127.0.0.1-only listener via localhost name';
ok $g->is_connected, 'client reports connected';

done_testing;
