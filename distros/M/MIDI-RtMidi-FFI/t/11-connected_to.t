use strict;
use warnings;

use Test2::V0;
use Test::Lib;
use MIDI::RtMidi::FFI::TestUtils;

plan skip_all => "Sanity check failed" unless sanity_check;

my ( $in, $out ) = ( newdevice( 'in' ), newdevice() );
isa_ok( $_, 'MIDI::RtMidi::FFI::Device' ) for ( $in, $out );

$in->open_virtual_port( 'bibble' );
$out->open_port_by_name( qr/bibble/i );

my $port_num = ( $out->get_ports_by_name( qr/bibble/i ) )[0];
like( $out->connected_to_name, qr/bibble/i, "connected_to_name set correctly" );
is( $out->connected_to, $port_num, "connected_to set correctly" );

$out->close_port;
is( $out->connected_to_name, undef, "connected_to_name unset correctly" );
is( $out->connected_to, undef, "connected_to unset correctly" );

done_testing;
