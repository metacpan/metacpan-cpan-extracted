use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use IO::Socket::INET;
use IO::Socket::UNIX;
use IO::EventMux;
use Socket;

pass "Skip for now"; exit;
use constant {
    SOL_IP => 0,
    IP_RECVERR => 11,
};

my $fh2 = IO::Socket::INET->new(
    Proto    => 'udp',
    Blocking => 0,
) or die("\n");


#require "sys/syscall.ph";
#syscall(&SYS_recvmsg, fileno $fh2, $msg, MSG_ERRQUEUE);

setsockopt($fh2, SOL_IP, IP_RECVERR, 1);
$fh2->send($fh2, pack_sockaddr_in(12345, inet_aton("127.0.0.1")), 'Test\n');
sleep 2;

#use Socket::MsgHdr;
my $msg;
#recvmsg($fh2, 512, MSG_ERRQUEUE) or die();
my $n = unpack("I",getsockopt($fh2, SOL_IP, IP_RECVERR));
print "$n\n";

exit;
my $mux = IO::EventMux->new();
$mux->add($fh2);
while(1) {
    my $event = $mux->mux(2);
    use Data::Dumper; print Dumper($event);
    if($event->{type} eq 'sent') {
        sleep 1;
        my $n = unpack("I",getsockopt($fh2, SOL_SOCKET, SO_ERROR));
        print "$n\n";

    } elsif($event->{type} eq 'error') {
        if($event->{error_type} eq 'connection') {
            pass "We got a connection error";
        } else {
            fail "We did not get a connection error";
        }
        exit;
    
    } elsif($event->{type} eq 'timeout') {
        fail "Got timeout??";
        exit;
    }
}

