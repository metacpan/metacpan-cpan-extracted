#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::Future::Deferred 0.52;  # ->flush method
use Test::Future::IO;

use constant HAVE_TEST_METRICS_ANY => eval { require Test::Metrics::Any };

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

# Most receive tests follow a similar structure
sub notifications_received_for
{
   my ( $bytes ) = @_;

   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( $bytes );
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_return( my $next_read_f = Future->new )
      ->will_also_later( sub { $slurm->stop; } );

   my @notifications;
   my $run_f = $slurm->run(
      on_notify => sub { push @notifications, [ $_[0], $_[1] ] }
   );
   Test::Future::Deferred->flush;

   ok( $next_read_f->is_cancelled, 'Next read future is cancelled' );

   return @notifications;
}

# Basic notification
{
   my ( $notification ) = notifications_received_for
      "\x55" . with_crc8( with_crc8( "\x11\x05\x01" ) . "A" );
   is( $notification, [ 5, "A" ], 'Received NOTIFY packet' );

   if( HAVE_TEST_METRICS_ANY ) {
      Test::Metrics::Any::is_metrics( {
         "slurm_packets dir:rx type:NOTIFY" => 1,
      }, 'Received NOTIFY packet increments metrics' );
   }

   $controller->check_and_clear( 'Receive NOTIFY packet' );
}

# Send
{
   $controller->use_sysread_buffer( "DummyFH" );

   # Reset
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x01\x87\x01" ) . "\x00" ) )
      ->will_write_sysread_buffer_later( "DummyFH", "\x55" . with_crc8( with_crc8( "\x02\x07\x01" ) . "\x00" ) );
   $controller->expect_sleep( Test::Deep::num( 0.0017, 1E-4 ) );
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x01\x87\x01" ) . "\x00" ) );
   $controller->expect_sleep( 0.05 * 3 )
      ->remains_pending;

   # There is no auto-reset for MSLuRM
   await $slurm->_reset( 7 );

   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x11\x87\x02" ) . "A1" ) );
   $controller->expect_sleep( Test::Deep::num( 0.0017, 1E-4 ) );
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x11\x87\x02" ) . "A1" ) );

   await $slurm->send_notify( 7, "A1" );

   if( HAVE_TEST_METRICS_ANY ) {
      Test::Metrics::Any::is_metrics( {
         "slurm_packets dir:tx type:NOTIFY" => 2,
      }, '->send_notify increments metrics' );
   }

   $controller->check_and_clear( '->send_notify' );

   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x12\x87\x02" ) . "B2" ) );
   $controller->expect_sleep( Test::Deep::num( 0.0017, 1E-4 ) );
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x12\x87\x02" ) . "B2" ) );

   await $slurm->send_notify( 7, "B2" );

   $controller->check_and_clear( '->send_notify again' );
}

done_testing;
