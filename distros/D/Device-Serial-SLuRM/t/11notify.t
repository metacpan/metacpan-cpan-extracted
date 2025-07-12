#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::Future::Deferred 0.52;  # ->flush method
use Test::Future::IO;

use constant HAVE_TEST_METRICS_ANY => eval { require Test::Metrics::Any };

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
      on_notify => sub { push @notifications, $_[0] }
   );
   Test::Future::Deferred->flush;

   ok( $next_read_f->is_cancelled, 'Next read future is cancelled' );

   return @notifications;
}

# Auto-reset
{
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_return( my $read1_f = Future->new );
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x01\x01" ) . "\x00" ) )
      ->will_also_later( sub { $read1_f->done( "\x55" . with_crc8( with_crc8( "\x02\x01" ) . "\x00" ) ); } );
   $controller->expect_sleep( Test::Deep::num( 0.0017, 1E-4 ) );
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_return( my $read2_f = Future->new )
      ->will_also_later( sub { $slurm->stop; } );
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x01\x01" ) . "\x00" ) );

   my $run_f = $slurm->run;
   $run_f->await;

   ok( $read2_f->is_cancelled, 'Second read future is cancelled after ->stop' );
}

# Basic notification
{
   my ( $notification ) = notifications_received_for
      "\x55" . with_crc8( with_crc8( "\x11\x01" ) . "A" );
   is( $notification, "A", 'Received NOTIFY packet' );

   if( HAVE_TEST_METRICS_ANY ) {
      Test::Metrics::Any::is_metrics( {
         "slurm_packets dir:rx type:NOTIFY" => 1,
      }, 'Received NOTIFY packet increments metrics' );
   }

   $controller->check_and_clear( 'Receive NOTIFY packet' );
}

# Duplicates are suppressed
{
   my @notifications = notifications_received_for
      "\x55" . with_crc8( with_crc8( "\x12\x01" ) . "B" ) .
      "\x55" . with_crc8( with_crc8( "\x12\x01" ) . "B" );
   is( \@notifications, [ "B" ], 'Received only one NOTIFY packet with duplicate' );

   $controller->check_and_clear( 'Receive NOTIFY packet with duplicate' );
}

# Backwards steps are suppressed
{
   my @notifications = notifications_received_for
      "\x55" . with_crc8( with_crc8( "\x13\x01" ) . "C" ) .
      "\x55" . with_crc8( with_crc8( "\x12\x01" ) . "B" );
   is( \@notifications, [ "C" ], 'Received only one NOTIFY packet with backstep' );

   $controller->check_and_clear( 'Receive NOTIFY packet with backstep' );
}

# Gaps in the sequence are accepted
{
   my @notifications = notifications_received_for
      "\x55" . with_crc8( with_crc8( "\x14\x01" ) . "D" ) .
      "\x55" . with_crc8( with_crc8( "\x16\x01" ) . "E" ) .
      "\x55" . with_crc8( with_crc8( "\x1A\x01" ) . "F" );
   is( \@notifications, [ "D", "E", "F" ], 'Received all three NOTIFY packets with gaps' );

   $controller->check_and_clear( 'Receive NOTIFY packets with gap' );
}

# Wraparound at end of range is accepted
{
   my @notifications = notifications_received_for
      "\x55" . with_crc8( with_crc8( "\x1F\x01" ) . "G" ) .
      "\x55" . with_crc8( with_crc8( "\x10\x01" ) . "H" );
   is( \@notifications, [ "G", "H" ], 'Received only one NOTIFY packet with wraparound' );

   $controller->check_and_clear( 'Receive NOTIFY packets with wraparound' )
}

# Send
{
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x11\x02" ) . "A1" ) );
   $controller->expect_sleep( Test::Deep::num( 0.0017, 1E-4 ) );
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x11\x02" ) . "A1" ) );

   await $slurm->send_notify( "A1" );

   if( HAVE_TEST_METRICS_ANY ) {
      Test::Metrics::Any::is_metrics( {
         "slurm_packets dir:tx type:NOTIFY" => 2,
      }, '->send_notify increments metrics' );
   }

   $controller->check_and_clear( '->send_notify' );

   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x12\x02" ) . "B2" ) );
   $controller->expect_sleep( Test::Deep::num( 0.0017, 1E-4 ) );
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x12\x02" ) . "B2" ) );

   await $slurm->send_notify( "B2" );

   $controller->check_and_clear( '->send_notify again' );
}

done_testing;
