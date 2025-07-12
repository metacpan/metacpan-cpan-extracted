#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::Future::Deferred 0.52;  # ->flush method
use Test::Future::IO 0.05;

use constant HAVE_TEST_METRICS_ANY => eval {
   require Test::Metrics::Any;
   require Metrics::Any::Adapter::Test and Metrics::Any::Adapter::Test->VERSION( '0.08' );

   Metrics::Any::Adapter::Test->use_full_distributions;
};

use Future::AsyncAwait;

use Device::Serial::SLuRM;

use Digest::CRC qw( crc8 );

my $controller = Test::Future::IO->controller;

my $slurm = Device::Serial::SLuRM->new( fh => "DummyFH" );

sub with_crc8
{
   my ( $data ) = @_;
   return pack "a* C", $data, crc8( $data );
}

# Auto-reset
{
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_return( my $read1_f = Future->new );
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x01\x01" ) . "\x00" ) )
      ->will_also_later( sub { $read1_f->done( "\x55" . with_crc8( with_crc8( "\x02\x01" ) . "\x00" ) ); } );
   $controller->expect_sleep( Test::Deep::num( 0.0017, 1E-4 ) );
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_return( Future->new )
      ->will_also_later( sub { $slurm->stop; } );
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x01\x01" ) . "\x00" ) );

   my $run_f = $slurm->run;
   $run_f->await;
}

# Request
{
   Metrics::Any::Adapter::Test->clear if HAVE_TEST_METRICS_ANY;

   $controller->use_sysread_buffer( "DummyFH" );

   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( "\x55" . with_crc8( with_crc8( "\x31\x01" ) . "G" ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xB1\x01" ) . "H" ) );
   # ACK is sent twice
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( "\x55" . with_crc8( with_crc8( "\xC1\x00" ) ) );
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( "\x55" . with_crc8( with_crc8( "\xC1\x00" ) ) );
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_return( my $next_read_f = Future->new )
      ->will_also_later( sub { $slurm->stop; } );

   my @requests;
   my $run_f = $slurm->run(
      handle_request => async sub {
         my ( $payload ) = @_;
         push @requests, $payload;
         return "H";
      },
   );
   Test::Future::Deferred->flush;

   is( \@requests, [ "G" ], 'Receive REQUEST packet' );

   if( HAVE_TEST_METRICS_ANY ) {
      Test::Metrics::Any::is_metrics( {
         "slurm_packets dir:rx type:REQUEST"  => 1,
         "slurm_packets dir:tx type:RESPONSE" => 1,
         "slurm_packets dir:rx type:ACK"      => 2,
      }, 'Received request/response transaction increments metrics' );
   }

   $controller->check_and_clear( 'Receive REQUEST packet' );
}

# Resends RESPONSE on duplicate request
{
   Metrics::Any::Adapter::Test->clear if HAVE_TEST_METRICS_ANY;

   $controller->use_sysread_buffer( "DummyFH" );

   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( "\x55" . with_crc8( with_crc8( "\x32\x01" ) . "I" ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xB2\x01" ) . "J" ) );
   # Duplicate REQUEST
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( "\x55" . with_crc8( with_crc8( "\x32\x01" ) . "I" ) );
   # .. resends same response
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xB2\x01" ) . "J" ) );
   # ACK is sent twice
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( "\x55" . with_crc8( with_crc8( "\xC2\x00" ) ) );
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( "\x55" . with_crc8( with_crc8( "\xC2\x00" ) ) );
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_return( my $next_read_f = Future->new )
      ->will_also_later( sub { $slurm->stop; } );

   my @requests;
   my $run_f = $slurm->run(
      handle_request => async sub {
         my ( $payload ) = @_;
         push @requests, $payload;
         return "J";
      },
   );
   Test::Future::Deferred->flush;

   is( \@requests, [ "I" ], 'Receive REQUEST packet once only' );

   if( HAVE_TEST_METRICS_ANY ) {
      Test::Metrics::Any::is_metrics( {
         "slurm_packets dir:rx type:REQUEST"  => 2,
         "slurm_packets dir:tx type:RESPONSE" => 2,
         "slurm_packets dir:rx type:ACK"      => 2,
      }, 'Received request/response transaction increments metrics' );
   }

   $controller->check_and_clear( 'Receive REQUEST packet' );
}

done_testing;
