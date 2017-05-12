use strict;
use warnings;

use Test::More tests => 7;
use IO::EventMux;

my $PORT = 7007;

my $hasIOBuffered = 1;

eval 'require IO::Buffered';
if ($@) {
    $hasIOBuffered = 0;
}


SKIP: {
    skip "IO::Buffered not installed", 7 unless $hasIOBuffered;

    my $mux = IO::EventMux->new();

    # Test Listning TCP sockets
    my $listener = IO::Socket::INET->new(
        Listen    => 5,
        LocalPort => $PORT,
        ReuseAddr => 1,
        Blocking => 0,
    ) or die "Listening on port $PORT: $!\n";

    print "listener:$listener\n";
    $mux->add($listener, Listen => 1, Buffered => new IO::Buffered(Split => qr/\n/));

    my $talker = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerAddr => '127.0.0.1',
        PeerPort => $PORT,
        Blocking => 1,
    ) or die "Connecting to 127.0.0.1:$PORT: $!\n";
    print "talker:$talker\n";
    $mux->add($talker, Buffered => new IO::Buffered(Regexp => qr/(.*\n)/));

    my @dataset = ("data 1\n", "data 2\n", "data 3");
    my @dataset_connecter;
    my @dataset_talker;

    $mux->send($talker, @dataset);
    push(@dataset_connecter, @dataset);

    my $time = time;
    my $timeout = 1;
    my $connecter;
    my %disconnected_fhs;
    while(1) {
        my $event = $mux->mux($timeout);
        my $type  = $event->{type};
        my $fh    = ($event->{fh} or '');
        my $data  = ($event->{data} or '');

        print "$fh $type: $data\n";

        if($type eq 'ready') {

        } elsif($type eq 'accepted') {
            $connecter = $fh;

        } elsif($type eq 'closing') {

        } elsif($type eq 'closed') {
            $disconnected_fhs{$fh} = 1;
            if(keys %disconnected_fhs == 2) { last; }

        } elsif($type eq 'read' and $fh eq $connecter) {
            my $test = shift @dataset_connecter;

            # Send some data to talker
            $mux->send($fh, $test);
            push(@dataset_talker, $test);

            # Remove the line break before we compare.
            $test =~ s/\n$//;
            ok($event->{data} eq $test, 
                "Read from $fh with Split buffering:".
                "'$test' = '$event->{data}'");

        } elsif($type eq 'read' and $fh eq $talker) {
            my $test = shift @dataset_talker;
            ok($event->{data} eq $test, 
                "We got god read from $fh with Regexp buffering:". 
                "'$test' = '$event->{data}'");

        } elsif($type eq 'read_last') {

        } elsif($type eq 'sent') {

        } elsif($type eq 'timeout') {
            ok(time-$time-$timeout <= 1, 
                "Timeout difference was not to long: 1 >= ".(time-$time-$timeout));
            ok(time-$time-$timeout >= 0, 
                "Timeout difference was not to short: 0 <= ".(time-$time-$timeout));
            $mux->close($talker);

        } else {
            die("Unhandled event $type");
        }

    }
}
