use strict;
use warnings;

use Test::More tests => 1;

use IO::EventMux;
use Data::Dumper;

my $PORT = 7007;


my $hasIOBuffered = 1;

eval 'require IO::Buffered::HTTP';
if ($@) {
    $hasIOBuffered = 0;
}

SKIP: {
    skip "IO::Buffered not installed", 1 unless $hasIOBuffered;

    my $mux = IO::EventMux->new;

    # Test Listning TCP sockets
    my $listener = IO::Socket::INET->new(
        Listen    => 5,
        LocalPort => $PORT,
        ReuseAddr => 1,
        Blocking => 0,
    ) or die "Listening on port $PORT: $!\n";
    $mux->add($listener, Listen => 1, Buffered => new IO::Buffered(Split => qr/\n/));

    my $talker = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerAddr => '127.0.0.1',
        PeerPort => $PORT,
        Blocking => 1,
    ) or die "Connecting to 127.0.0.1:$PORT: $!\n";
    $mux->add($talker);

    my $count = 20;

    $mux->send($talker, "data 1\n" x $count);

    while(1) {
        my $event = $mux->mux(10);
        next if $event->{type} ne 'read';
        last if --$count == 0;
        #print Dumper($event);   
    }

    pass("We got all data");
}
