use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use IO::Socket::INET;
use IO::EventMux;
use Socket;

my $fh2 = IO::Socket::INET->new(
    PeerAddr => '127.0.0.1',
    PeerPort => 12345,
    Proto    => 'udp',
    Blocking => 0,
) or die("\n");

my $mux = IO::EventMux->new();
$mux->add($fh2);
$mux->send($fh2, "Test\n");

while(1) {
    my $event = $mux->mux(2);
    use Data::Dumper; print Dumper($event);
    
    if($event->{type} eq 'error') {
        if($event->{error} =~ /Connection refused/) {
            pass "We got a connection refused";
        } else {
            fail "We did not get a connection error";
        }
        exit;
    
    } elsif($event->{type} eq 'timeout') {
        fail "Got timeout??";
        exit;
    }
}


