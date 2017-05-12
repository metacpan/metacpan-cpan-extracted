use strict;
use warnings;

use Test::More tests => 1;
use IO::EventMux::Dump;
use IO::Socket::INET;
use IO::Select;
use Socket;

# Test that we can send and read data with udp.
my $fh = IO::Socket::INET->new(
    LocalPort    => 10045,
    LocalAddr    => "127.0.0.1",
    ReuseAddr    => 1,    
    Proto        => 'udp',
    Blocking     => 0,
) or die "Could not open socket on (127.0.0.1:10045): $!\n";

my $mux = IO::EventMux::Dump->new();
$mux->add($fh);

my $pid = fork;
if($pid == 0) {
    close $fh;
    my $fh = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => 10045,
        Proto    => 'udp',
        Blocking => 0,
    ) or die "Could not open socket on 127.0.0.1 : $!\n";
    $fh->send("hello\n");
    close $fh;
    exit;
}

while (my $event = $mux->mux()) {
    use Data::Dumper; print Dumper($event);
    if($event->{type} eq 'read' and $event->{data} eq "hello\n") {
        pass("Socket was detected as UDP and we got our data");
    } else {
        fail("Socket was not detected as UDP or we did not get the right data");
    }
    exit;
}

waitpid($pid, 0);
