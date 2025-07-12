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

# Send request (ideal)
{
   if( HAVE_TEST_METRICS_ANY ) {
      Metrics::Any::Adapter::Test->override_timer_duration( 0.1 );
   }

   $controller->use_sysread_buffer( "DummyFH" );

   # Auto-reset
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x01\x01" ) . "\x00" ) )
      ->will_write_sysread_buffer_later( "DummyFH", "\x55" . with_crc8( with_crc8( "\x02\x01" ) . "\x00" ) );
   $controller->expect_sleep( Test::Deep::num( 0.0017, 1E-4 ) );
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x01\x01" ) . "\x00" ) );
   $controller->expect_sleep( 0.05 * 3 )
      ->remains_pending;

   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x31\x03" ) . "req" ) )
      ->will_write_sysread_buffer_later( "DummyFH",
         "\x55" . with_crc8( with_crc8( "\xB1\x03" ) . "res" ) );
   $controller->expect_sleep( 0.05 )
      ->will_return( my $retransmit_f = Future->new );
   # ACK is sent twice
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC1\x00" ) ) );
   $controller->expect_sleep( Test::Deep::num( 0.0017, 1E-4 ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC1\x00" ) ) );

   is( await $slurm->request( "req" ), "res",
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

# Send request (errored)
{
   $controller->use_sysread_buffer( "DummyFH" );

   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x32\x03" ) . "req" ) )
      ->will_write_sysread_buffer_later( "DummyFH",
         "\x55" . with_crc8( with_crc8( "\xE2\x03" ) . "err" ) );
   $controller->expect_sleep( 0.05 )
      ->remains_pending;
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC2\x00" ) ) );
   $controller->expect_sleep( Test::Deep::num( 0.0017, 1E-4 ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC2\x00" ) ) );

   my $f = $slurm->request( "req" );
   $f->await;
   is( [ $f->failure ], [ "Received ERR packet <65.72.72>", slurm => "err" ],
      'Request future failed with error' );

   $controller->check_and_clear( '->request for error' );

   $slurm->stop;
}

# REQUEST is retransmitted
{
   $controller->use_sysread_buffer( "DummyFH" );

   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x33\x04" ) . "req2" ) );
   $controller->expect_sleep( 0.05 )
      ->will_done(); # timeout happens
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x33\x04" ) . "req2" ) ) # retransmitted
      ->will_write_sysread_buffer_later( "DummyFH",
         "\x55" . with_crc8( with_crc8( "\xB3\x04") . "res2" ) );
   $controller->expect_sleep( 0.05 )
      ->remains_pending;
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC3\x00" ) ) );
   $controller->expect_sleep( Test::Deep::num( 0.0017, 1E-4 ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC3\x00" ) ) );

   is( await $slurm->request( "req2" ), "res2",
      '->request runs command and yields response after retransmit' );

   if( HAVE_TEST_METRICS_ANY ) {
      Test::Metrics::Any::is_metrics( {
         "slurm_retransmits" => 1,
         "slurm_request_success_attempts[2]" => 1,
      }, 'Packet retransmit increments metrics' );
   }

   $controller->check_and_clear( '->request for retransmit' );

   $slurm->stop;
}

# No response eventually fails f
{
   $controller->use_sysread_buffer( "DummyFH" );

   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x34\x04" ) . "req3" ) );
   $controller->expect_sleep( 0.05 )
      ->will_done(); # timeout happens
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x34\x04" ) . "req3" ) );
   $controller->expect_sleep( 0.05 )
      ->will_done(); # timeout happens
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x34\x04" ) . "req3" ) );
   $controller->expect_sleep( 0.05 )
      ->will_done(); # timeout happens

   my $f = $slurm->request( "req3" );
   $f->await;
   is( [ $f->failure ], [ "Request timed out after 3 attempts\n", slurm => undef ],
      'Eventual failure of ->request timeout' );

   if( HAVE_TEST_METRICS_ANY ) {
      Test::Metrics::Any::is_metrics( {
         "slurm_timeouts" => 1,
      }, 'Packet timeout increments metrics' );
   }

   $controller->check_and_clear( '->request for timeout' );

   $slurm->stop;
}

# RESPONSEs do not need to be sequential
{
   $controller->use_sysread_buffer( "DummyFH" );

   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x35\x02" ) . "R1" ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x36\x02" ) . "R2" ) );
   $controller->expect_sleep( 0.05 )
      ->remains_pending;
   $controller->expect_sleep( 0.05 )
      ->remains_pending
      ->will_write_sysread_buffer_later( "DummyFH",
         "\x55" . with_crc8( with_crc8( "\xB6\x02" ) . "A2" ) .
         "\x55" . with_crc8( with_crc8( "\xB5\x02" ) . "A1" ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC6\x00" ) ) );
   $controller->expect_sleep( Test::Deep::num( 0.0017, 1E-4 ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC6\x00" ) ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC5\x00" ) ) );
   $controller->expect_sleep( Test::Deep::num( 0.0017, 1E-4 ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC5\x00" ) ) );

   my $f1 = $slurm->request( "R1" );
   my $f2 = $slurm->request( "R2" );

   is( scalar await $f1, "A1", 'Reply to R1' );
   is( scalar await $f2, "A2", 'Reply to R2' );

   $controller->check_and_clear( 'Responses to ->request delivered out of order' );

   $slurm->stop;
}

# Request can be cancelled without upsetting anything
{
   $controller->use_sysread_buffer( "DummyFH" );

   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x37\x07" ) . "no-need" ) );
   $controller->expect_sleep( 0.05 )
      ->remains_pending;

   my $f = $slurm->request( "no-need" );
   Test::Future::Deferred->flush;
   $f->cancel;

   ok( $f->is_cancelled, '$f was cancelled' ) or
      $f->get;

   # A later request works fine
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x38\x05" ) . "later" ) )
      ->will_write_sysread_buffer_later( "DummyFH",
         "\x55" . with_crc8( with_crc8( "\xB8\x04" ) . "fine" ) );
   $controller->expect_sleep( 0.05 )
      ->remains_pending;
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC8\x00" ) ) );
   $controller->expect_sleep( Test::Deep::num( 0.0017, 1E-4 ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC8\x00" ) ) );

   is( await $slurm->request( "later" ), "fine",
      'later ->request after cancel yields response' );

   $controller->check_and_clear( '->request cancelled' );

   $slurm->stop;
}

done_testing;
