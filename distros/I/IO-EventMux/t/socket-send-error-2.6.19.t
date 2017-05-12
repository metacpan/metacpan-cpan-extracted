use strict;
use warnings;

use Test::More tests => 1;
use IO::Socket::INET;
use IO::Select;
use Socket;

# Test that we can do a async tcp connect of many sockets.
my $fhnum = 1014;

my $error;
foreach my $i (1..$fhnum) {
    my $fh = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => 10045,
        Proto    => 'udp',
        Type     => SOCK_DGRAM,
        Blocking => 1,
    ) or die "Could not open socket on 127.0.0.1($i) : $!\n";
    my $addr = pack_sockaddr_in(1000, inet_aton("127.0.0.1"));
    my $rv = $fh->send("", 0, $addr);
    if(!defined $rv) {
        print "would block: $i\n";
        $error = $!;
        last;
    }
}
ok(!defined $error, "We could send to an open udp socket");


