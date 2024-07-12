#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::Future::IO;

use constant HAVE_TEST_METRICS_ANY => eval { require Test::Metrics::Any };

use Future::AsyncAwait;

use Device::Serial::SLuRM::Protocol;

use Digest::CRC qw( crc8 );

my $controller = Test::Future::IO->controller;

$controller->use_sysread_buffer( "DummyFH" )
   ->indefinitely;

my $proto = Device::Serial::SLuRM::Protocol->new( fh => "DummyFH", multidrop => 1 );

sub with_crc8
{
   my ( $data ) = @_;
   return pack "a* C", $data, crc8( $data );
}

# recv
{
   $controller->write_sysread_buffer( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x10\xB0\x03" ) . "ABC" ) );

   is( [ await $proto->recv ], [ 0x10, 0xB0, "ABC" ],
      'One packet received by ->recv' );

   if( HAVE_TEST_METRICS_ANY ) {
      Test::Metrics::Any::is_metrics( {
         # SYNC + 3*header + CRC + 3*body + CRC = 9
         "slurm_serial_bytes dir:rx" => 9,
      }, '->recv increments byte-counter metric' );
   }

   $controller->check_and_clear( '->recv' );

   # Two packets combined

   $controller->write_sysread_buffer( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x11\xB1\x01" ) . "1" ) .
      "\x55" . with_crc8( with_crc8( "\x12\xB2\x01" ) . "2" ) );

   is( [ await $proto->recv ], [ 0x11, 0xB1, "1" ],
      'First of two packets received by ->recv' );
   is( [ await $proto->recv ], [ 0x12, 0xB2, "2" ],
      'Second of two packets received by ->recv' );

   $controller->check_and_clear( '->recv combined' );
}

# send
{
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x18\x31\x03" ) . "DEF" ) );

   await $proto->send( 0x18, 0x31, "DEF" );

   if( HAVE_TEST_METRICS_ANY ) {
      Test::Metrics::Any::is_metrics( {
         # SYNC + 3*header + CRC + 3*body + CRC = 9
         "slurm_serial_bytes dir:tx" => 9,
      }, '->send_packet increments byte-counter metric' );
   }

   $controller->check_and_clear( '->send' );
}

done_testing;
