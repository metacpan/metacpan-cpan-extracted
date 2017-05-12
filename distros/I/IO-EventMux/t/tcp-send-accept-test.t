use strict;
use warnings;

use Test::More tests => 1;
use IO::Socket::INET;
use IO::Select;
use Socket;

# Test that we can do a async tcp connect of many sockets.
my $fhnum = 1014;

my $error;
my $s = IO::Select->new();
my $fh = IO::Socket::INET->new(
    LocalPort    => 10045,
    LocalAddr    => "127.0.0.1",
    Proto        => 'tcp',
    Blocking     => 1,
    ReuseAddr    => 1,
    Listen       => 1020, 
) or die "Could not open socket on (127.0.0.1:10045): $!\n";

my $pid = fork;
if($pid == 0) {
    close $fh;
    foreach my $i (1..$fhnum) {
        my $fh = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => 10045,
            Proto    => 'tcp',
            #Type     => SOCK_DGRAM,
            Blocking => 1,
        ) or die "Could not connect to socket on 127.0.0.1:10045($i) : $!\n";
        my $addr = pack_sockaddr_in(1000, inet_aton("127.0.0.1"));
        my $rv = $fh->send("", 0, $addr);
        if(!defined $rv) {
            print "would block: $i\n";
            last;
        } else {
            #print "open $i\n";
        }
    }
    exit;
}

$s->add($fh);
foreach my $num (1..$fhnum) {
    if($s->can_read(5)) {
        my $newfh = $fh->accept();
        if($newfh) {
            shutdown $newfh, 2;
            close $newfh;
        } else {
            print "empty\n";
        }
    } else {
        $error = "Did not get any connects in 5 seconds";
        last;
    }
}

waitpid($pid, 0);
ok(!defined $error, "We could send to an open tcp socket: ".($error or ''));
