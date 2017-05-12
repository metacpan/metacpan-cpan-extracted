use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use IO::Socket::INET;
use IO::EventMux;
use Socket;

my $fh1 = IO::Socket::INET->new(
    PeerAddr => '127.0.0.1',
    PeerPort => 12345,
    Proto    => 'tcp',
    Blocking => 0,
) or die("\n");

my $mux = IO::EventMux->new();
$mux->add($fh1);

while(1) {
    my $event = $mux->mux(2);
    use Data::Dumper; print Dumper($event);
    if($event->{type} eq 'error') {
        ok($event->{error} =~ 'Connection refused', "We got a connection refused");
        exit;
    } elsif($event->{type} eq 'timeout') {
        fail "Got timeout??";
        exit;
    }
}


