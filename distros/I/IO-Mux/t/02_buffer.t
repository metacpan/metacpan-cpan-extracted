use strict ;
use IO::Handle ;

use Test::More tests => 14 ;
BEGIN { use_ok('IO::Mux::Buffer') } ;
use IO::Mux::Packet ;

my $b = new IO::Mux::Buffer() ;
my $p1 = new IO::Mux::Packet('a', "test packet1") ;
my $p2 = new IO::Mux::Packet('a', "test packet2") ;

$b->push_packet($p1) ;
is($b->get_length(), 12) ;
is($b->get_data(), 'test packet1') ;

$b->push_packet($p2) ;
is($b->get_length(), 24) ;
is($b->get_data(), 'test packet1test packet2') ;

my $data = $b->shift_data(5) ;
is($data, 'test ') ;
is($b->get_data(), 'packet1test packet2') ;
$data = $b->shift_data(4) ;
is($data, 'pack') ;
is($b->get_data(), 'et1test packet2') ;

$data = $b->shift_data() ;
is($data, '') ;

$data = $b->shift_data($b->get_length()) ;
is($data, 'et1test packet2') ;
is($b->get_data(), '') ;

eval {
	$data = $b->shift_data(3) ;
} ;
like($@, qr/Buffer contains less than/) ;

$b->push_packet($p1) ;
$data = $b->shift_data(-1) ;
is($data, '') ;
