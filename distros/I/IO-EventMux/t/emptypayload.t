use strict;
use warnings;

use Test::More tests => 1;
use IO::EventMux;
use IO::Socket::INET;

# Test that we can send and read data with udp.
my $udp = IO::Socket::INET->new(
    LocalPort    => 10045,
    LocalAddr    => "127.0.0.1",
    ReuseAddr    => 1,    
    Proto        => 'udp',
    Blocking     => 1,
) or die "Could not open socket on (127.0.0.1:10045): $!\n";

# Test that we can send and read data with udp.
my $tcp = IO::Socket::INET->new(
    LocalPort    => 10045,
    LocalAddr    => "127.0.0.1",
    ReuseAddr    => 1,    
    Proto        => 'tcp',
    Blocking     => 1,
    Listen       => 5, 
) or die "Could not open socket on (127.0.0.1:10046): $!\n";

my $mux = IO::EventMux->new();
$mux->add($udp);
$mux->add($tcp);

my $pid1 = fork;
if($pid1 == 0) {
    close $udp;
    close $tcp;
    my $fh = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => 10045,
        Proto    => 'udp',
        Blocking => 1,
    ) or die "Could not open socket on 127.0.0.1 : $!\n";
    $fh->send("");
    close $fh;
    exit;
}

my $pid2 = fork;
if($pid2 == 0) {
    close $udp;
    close $tcp;
    my $fh = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => 10045,
        Proto    => 'tcp',
        Blocking => 1,
    ) or die "Could not open socket on 127.0.0.1 : $!\n";
    $fh->send("");
    $fh->send("test");
    close $fh;
    exit;
}


my $count = 0;
while (my $event = $mux->mux()) {
    use Data::Dumper; print Dumper($event);

    if($event->{fh} eq $udp) {
        if($event->{type} eq 'read' and $event->{data} eq "") {
            pass("We got the empty payload");
        } else {
            fail("Something went wrong with UDP");
        }   
    }
    if($event->{fh} eq $tcp) {
        if($event->{type} eq 'read' and $event->{data} eq "test") {
            pass("We got payload of test");
        } else {
            fail("Something went wrong TCP");
        }   
    }

    if($count++ == 2) { exit; }
}

waitpid($pid1, 0);
waitpid($pid2, 0);

