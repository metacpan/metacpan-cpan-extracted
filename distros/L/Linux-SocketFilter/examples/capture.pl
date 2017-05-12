#!/usr/bin/perl

use strict;
use warnings;

use Linux::SocketFilter;
use Linux::SocketFilter::Assembler qw( assemble );
use IO::Socket::Packet;
use Socket qw( SOCK_DGRAM );

my $sock = IO::Socket::Packet->new(
   IfIndex => 0,
   Type    => SOCK_DGRAM,
) or die "Cannot socket - $!";

$sock->attach_filter( assemble( <<"EOF" ) );
   LD AD[PROTOCOL]

   JEQ 0x0800, 0, 1
   RET 20

   JEQ 0x86dd, 0, 1
   RET 40

   RET 0
EOF

while( my $addr = $sock->recv( my $buffer, 40 ) ) {
   printf "Packet: %v02x\n", $buffer;
}
