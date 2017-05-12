use strict ;
use IO::Handle ;

use Test::More tests => 17 ;
BEGIN { use_ok('IO::Mux::Packet') } ;

my $p = new IO::Mux::Packet(1, "packet_data") ;
is($p->get_length(), 11) ;
is($p->get_data(), "packet_data") ;
is($p->get_id(), 1) ;

pipe(R, W) ;
W->autoflush(1) ;
$p->write(\*W) ;
$p = new IO::Mux::Packet(1, "packet_data2") ;
$p->write(\*W) ;

$p = IO::Mux::Packet->read(\*R) ;
is($p->get_length(), 11) ;
ok($p->get_data() eq "packet_data") ;
ok($p->get_id() == 1) ;
$p = IO::Mux::Packet->read(\*R) ;
ok($p->get_length() == 12) ;
ok($p->get_data() eq "packet_data2") ;

# Empty packet
$p = new IO::Mux::Packet(1) ;
ok($p->write(\*W)) ;

# EOF packets
$p = new IO::Mux::Packet(1) ;
$p->make_eof() ;
$p->write(\*W) ;
$p = IO::Mux::Packet->read(\*R) ;
ok($p->is_eof()) ;

close(W) ;
$p = IO::Mux::Packet->read(\*R) ;
is($p, 0) ;


# Invalid data 
pipe(R, W) ;
W->autoflush(1) ;
print W "1" ;
close(W) ;
eval {
	$p = IO::Mux::Packet->read(\*R) ;
} ;
like($@, qr/Unexpected EOF \(incomplete packet length\)/) ;

pipe(R, W) ;
W->autoflush(1) ;
$p = new IO::Mux::Packet(1, "packet") ;
my $bytes = $p->serialize() ;
chop($bytes) ;
print W $bytes ;
close(W) ;
eval {
	$p = IO::Mux::Packet->read(\*R) ;
} ;
like($@, qr/Unexpected EOF \(incomplete packet id or data\)/) ;

pipe(R, W) ;
W->autoflush(1) ;
$bytes = $p->serialize() ;
$bytes =~ s/\t/ /g ;
print W $bytes ;
close(W) ;
eval {
	$p = IO::Mux::Packet->read(\*R) ;
} ;
like($@, qr/Malformed packet: /) ;

pipe(R, W) ;
$bytes = $p->serialize() ;
substr($bytes, 0, 1, '!') ;
print W $bytes ;
close(W) ;
eval {
	$p = IO::Mux::Packet->read(\*R) ;
} ;
like($@, qr/Marker mismatch \(33,1\)/) ;

pipe(R, W) ;
$bytes = $p->serialize() ;
substr($bytes, 5, 1, '!') ;
print W $bytes ;
close(W) ;
eval {
	$p = IO::Mux::Packet->read(\*R) ;
} ;
like($@, qr/Marker mismatch \(1,33\)/) ;

