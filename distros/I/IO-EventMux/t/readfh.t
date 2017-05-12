use strict;
use warnings;

use Test::More tests => 1;

use IO::EventMux;
use Socket;
use IO::Socket::INET;
use Data::Dumper;

my $sock = IO::Socket::INET->new(
    Type     => SOCK_DGRAM,
    Proto    => "udp",
    Blocking => 0,
) or die "Creating socket: $!";

my $mux = new IO::EventMux();
$mux->add($sock, Errors => 1);

pass("SKIPED");

print($mux->isa('IO::Socket1')."\n");

$mux->_read_all($sock);

