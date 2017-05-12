use strict;
use warnings;

use Test::More tests => 2;

use IO::EventMux;
use Socket;

my $mux = IO::EventMux->new();

my $udpnc = IO::Socket::INET->new(
    ReuseAddr    => 1,    
    Proto        => 'udp',
    Blocking     => 0,
) or die "Could not open non connected udp socket: $!\n";
$mux->add($udpnc);

my $receiver = pack_sockaddr_in(161, inet_aton("255.255.255.255")); 
$mux->sendto($udpnc, $receiver, "hello");

my $event = $mux->mux();

pass("We did not die, so we handle network is unreachable on UDP");

if(($event->{error} or '') eq "Network is unreachable") {
    is_deeply($event, 
        { receiver => $receiver, 
            fh => $udpnc, 
            error => "Network is unreachable",
            type => 'error',
        }, "We get a correct event back");
} elsif(($event->{error} or '') eq "Permission denied") {
    pass "We are not allowed to send to 255.255.255.255 and this is OK";
} else {
    fail "We did not get an error???";
}
