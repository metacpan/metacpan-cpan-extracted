use strict;
use warnings;

use Test::More tests => 1;
use IO::Socket::INET;
use IO::Select;
use Benchmark qw(cmpthese);
use Socket;

use IO::EventMux;

my ($pid1, $fh1) = send_test(10045);
my ($pid2, $fh2) = send_test(10046);
my $mux = IO::EventMux->new();
$mux->add($fh2);

print "IO::EventMux: $IO::EventMux::VERSION\n";

cmpthese (-1, {
    sendrecv1 => sub { sendrecv($fh1); },
    eventmux  => sub { eventmux($mux, $fh2); },
});

kill 1, $pid1; waitpid($pid1, 0);
kill 1, $pid2; waitpid($pid2, 0);

exit;

sub sendrecv {
    my ($fh) = @_;
    $fh->recv(my $inData, 512, 0);
    my $event = {
        data => $inData, 
        fh => $fh, 
        sender => 'aaa',
    };
    $fh->send("hello\n");
}


sub eventmux {
    my ($mux, $fh) = @_;
    my $event = $mux->mux();
    if($event->{type} eq 'read') {
        #$fh->send("hello\n");
        $mux->send($fh, "hello\n");
    }
}

sub send_test {
    my ($port) = @_;
    # Test that we can send and read data with udp.
    my $fh = IO::Socket::INET->new(
        LocalPort    => $port,
        LocalAddr    => "127.0.0.1",
        ReuseAddr    => 1,    
        Proto        => 'udp',
        Blocking     => 1,
    ) or die "Could not open socket on (127.0.0.1:$port): $!\n";

    my $pid = fork;
    if($pid == 0) {
        close $fh;
        my $fh = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'udp',
            Blocking => 1,
        ) or die "Could not open socket to 127.0.0.1:$port : $!\n";
        while(1) {
            $fh->send("hello\n");
            $fh->recv(my $inData, 512, 0);
        }
        close $fh;
        exit;
    }
    return ($pid, $fh);
}





