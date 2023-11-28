#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::Future::IO 0.05;

use constant HAVE_TEST_METRICS_ANY => eval {
   require Test::Metrics::Any;
   require Metrics::Any::Adapter::Test and Metrics::Any::Adapter::Test->VERSION( '0.08' );

   Metrics::Any::Adapter::Test->use_full_distributions;
};

use Future::AsyncAwait;

use Device::Serial::MSLuRM;

use Digest::CRC qw( crc8 );

my $controller = Test::Future::IO->controller;

my $slurm = Device::Serial::MSLuRM->new( fh => "DummyFH" );

sub with_crc8
{
   my ( $data ) = @_;
   return pack "a* C", $data, crc8( $data );
}

# Send request (ideal)
{
   if( HAVE_TEST_METRICS_ANY ) {
      Metrics::Any::Adapter::Test->override_timer_duration( 0.1 );
   }

   $controller->use_sysread_buffer( "DummyFH" );

   # Auto-reset
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x01\x8F\x01" ) . "\x00" ) );
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x01\x8F\x01" ) . "\x00" ) );
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( "\x55" . with_crc8( with_crc8( "\x02\x0F\x01" ) . "\x00" ) );
   $controller->expect_sleep( 0.05 * 3 )
      ->remains_pending;

   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x31\x8F\x03" ) . "req" ) )
      ->will_write_sysread_buffer_later( "DummyFH",
         "\x55" . with_crc8( with_crc8( "\xB1\x0F\x03" ) . "res" ) );
   $controller->expect_sleep( 0.05 )
      ->will_return( my $retransmit_f = Future->new );
   # ACK is sent twice
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC1\x8F\x00" ) ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC1\x8F\x00" ) ) );

   is( await $slurm->request( 15 => "req" ), "res",
      '->request runs command and yields response' );

   ok( $retransmit_f->is_cancelled, 'Retransmit timer is cancelled' );

   if( HAVE_TEST_METRICS_ANY ) {
      Test::Metrics::Any::is_metrics( {
         "slurm_packets dir:tx type:REQUEST"  => 1,
         "slurm_packets dir:rx type:RESPONSE" => 1,
         "slurm_packets dir:tx type:ACK"      => 2,
         "slurm_request_success_attempts[1]"  => 1,
         "slurm_request_duration[0.100]"      => 1,
         "slurm_request_duration_count"       => 1,
      }, 'Request/response transaction increments metrics' );
   }

   $controller->check_and_clear( '->request' );

   $slurm->stop;
}

done_testing;
