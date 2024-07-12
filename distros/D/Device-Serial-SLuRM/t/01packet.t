#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::Future::IO;

use Future::Buffer 0.05; # immediate fill bugfix

use constant HAVE_TEST_METRICS_ANY => eval { require Test::Metrics::Any };

use Future::AsyncAwait;

use Device::Serial::SLuRM::Protocol;

use Digest::CRC qw( crc8 );

my $controller = Test::Future::IO->controller;

$controller->use_sysread_buffer( "DummyFH" )
   ->indefinitely;

my $proto = Device::Serial::SLuRM::Protocol->new( fh => "DummyFH" );

sub with_crc8
{
   my ( $data ) = @_;
   return pack "a* C", $data, crc8( $data );
}

# recv
{
   $controller->write_sysread_buffer( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x10\x03" ) . "ABC" ) );

   is( [ await $proto->recv ], [ 0x10, 0, "ABC" ],
      'One packet received by ->recv' );

   if( HAVE_TEST_METRICS_ANY ) {
      Test::Metrics::Any::is_metrics( {
         # SYNC + 2*header + CRC + 3*body + CRC = 8
         "slurm_serial_bytes dir:rx" => 8,
      }, '->recv increments byte-counter metric' );
   }

   $controller->check_and_clear( '->recv' );

   # Two packets combined

   $controller->write_sysread_buffer( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x11\x01" ) . "1" ) .
      "\x55" . with_crc8( with_crc8( "\x12\x01" ) . "2" ) );

   is( [ await $proto->recv ], [ 0x11, 0, "1" ],
      'First of two packets received by ->recv' );
   is( [ await $proto->recv ], [ 0x12, 0, "2" ],
      'Second of two packets received by ->recv' );

   $controller->check_and_clear( '->recv combined' );
}

# send
{
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x18\x03" ) . "DEF" ) );

   await $proto->send( 0x18, 0, "DEF" );

   if( HAVE_TEST_METRICS_ANY ) {
      Test::Metrics::Any::is_metrics( {
         # SYNC + 2*header + CRC + 3*body + CRC = 8
         "slurm_serial_bytes dir:tx" => 8,
      }, '->send_packet increments byte-counter metric' );
   }

   $controller->check_and_clear( '->send' );
}

done_testing;
