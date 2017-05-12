use strict;
use warnings;

use Test::More tests => 2;

use IO::EventMux;
use Socket;
use IO::Socket::INET;
use Data::Dumper;

eval "use IO::EventMux::Socket::MsgHdr qw(socket_errors);"; ## no critic
if($@) {
    pass "You need to install IO::EventMux::Socket::MsgHdr to run this test";
    pass "";
    exit;
}

my $sock = IO::Socket::INET->new(
    Type     => SOCK_DGRAM,
    Proto    => "udp",
    Blocking => 0,
) or die "Creating socket: $!";

my $mux = new IO::EventMux();
$mux->add($sock, Errors => 1);

my $dest = pack_sockaddr_in(1234, inet_aton("127.0.0.1"));
my $e_s = $mux->sendto($sock, $dest, "Hello, World");

my @result;
while(my $event = $mux->mux()) {
    print Dumper($event);
    is($event->{fh}, $sock, "We got a sent event") if $event->{type} eq 'sent';
    if ($event->{type} eq 'error') {
        is_deeply($event, { fh => $sock, from => '127.0.0.1', 
            data     => 'Hello, World',
            dst_port => 1234,
            type     => 'error',
            errno    => 111,
            error    => 'Connection refused',
            dst_ip   => '127.0.0.1',
        }, "We got a correct error event");
    last;
    }
}

