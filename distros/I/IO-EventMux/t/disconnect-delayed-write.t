use strict;
use warnings;

use Test::More tests => 1;
use IO::EventMux;
use Socket;

# FIXME: This tests how we deal with DelayedBy=>'write' option in the 
# disconnect call.

ok(1==1, "Skip this test until we have written it");

exit;

my $mux = IO::EventMux->new();

my $fh = IO::Socket::INET->new(
    Proto    => 'tcp',
    Type     => SOCK_DGRAM,
    Blocking => 0,
) or die "Could not open socket on 127.0.0.1: $!\n";
    
$mux->add($fh);
    
while(1) {
    my $event = $mux->mux(2);
    if($event->{type} eq 'timeout') {
        exit;
    }
}
