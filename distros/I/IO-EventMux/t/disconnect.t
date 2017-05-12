use strict;
use warnings;

# This tests how we handle a premature disconnect where a socket is 
# disconnected before we have called mux on it.
#
# It also looks at the order of the events pr. file handle so we are sure 
# EventMux returns them in the correct order:
#
# 1. connect or connected: Is the first event depending if it's from a 
#    accept call(ie. a child of a listening socket) or a connecting socket.
# 2. read, canread: is optional and might not happen as the other end can quit
#    before sending any data.
# 3. disconnect: Happens when using delayed disconnect, all disconnects EventMux 
#    detects is delayed. The user has to call disconnect($fh, 1); to get this 
#    event.
# 4. disconnected: Is the last event a file handle can generate.
#
#
#
#
use Test::More tests => 4;
use IO::EventMux;

my $hasIOBuffered = 1;

eval 'require IO::Buffered';
if ($@) {
    $hasIOBuffered = 0;
}

SKIP: {
    skip "IO::Buffered not installed", 4 unless $hasIOBuffered;

    my $PORT = 7007;

    my $mux = IO::EventMux->new();

    # Test Listning TCP sockets
    my $listener = IO::Socket::INET->new(
        Listen    => 5,
        LocalPort => $PORT,
        ReuseAddr => 1,
        Blocking => 0,
    ) or die "Listening on port $PORT: $!\n";

    print "listener:$listener\n";
    $mux->add($listener, Listen => 1, Buffered => new IO::Buffered(Regexp => qr/(.*?)\n/));

    my $talker = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerAddr => '127.0.0.1',
        PeerPort => $PORT,
        Blocking => 1,
    ) or die "Connecting to 127.0.0.1:$PORT: $!\n";
    print "talker:$talker\n";
    $mux->add($talker);
    $mux->send($talker, ("data 1\n", "data 2\n", "data 3"));

    my $child;
    my $timeout = 10;
    my $clients = 2;
    my %eventorder;
    while(1) {
        my $event = $mux->mux($timeout);
        my $fh    = ($event->{fh} or '');

        #use Data::Dumper;print Dumper($event);

        push(@{$eventorder{$fh}}, $event->{type});

        if($event->{type} eq 'ready') {

        } elsif($event->{type} eq 'accepted') {
            $child = $event->{fh};

        } elsif($event->{type} eq 'closing') {

        } elsif($event->{type} eq 'closed') {
            is($event->{missing}, 0, "missing should be 0");
            print "$clients\n";
            if(--$clients == 0) { last }

        } elsif($event->{type} eq 'sent' and $fh eq $talker) {
            $mux->close($talker);
        }
    }

    is_deeply($eventorder{$talker}, 
        [qw(ready sent closing closed)], "Event order for talker is correct");
    is_deeply($eventorder{$child}, 
        [qw(accepted read read read_last closing closed)], 
        "Event order for listener is correct");
}
