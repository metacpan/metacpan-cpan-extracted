#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::Future::Deferred 0.52;  # ->flush method
use Test::Future::IO 0.05;

use Future::AsyncAwait;

use Device::Serial::SLuRM;

use Digest::CRC qw( crc8 );

my $controller = Test::Future::IO->controller;

my $slurm = Device::Serial::SLuRM->new( fh => "DummyFH" );

$controller->use_sysread_buffer( "DummyFH" )
   ->indefinitely;

sub with_crc8
{
   my ( $data ) = @_;
   return pack "a* C", $data, crc8( $data );
}

# Initiate reset
{
   use Object::Pad::MetaFunctions qw( get_field );

   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x01\x01" ) . "\x00" ) )
      ->will_write_sysread_buffer_later( "DummyFH", "\x55" . with_crc8( with_crc8( "\x02\x01" ) . "\x04" ) );
   $controller->expect_sleep( Test::Deep::num( 0.0017, 1E-4 ) );
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x01\x01" ) . "\x00" ) );
   $controller->expect_sleep( 0.05 * 3 )
      ->remains_pending;

   await $slurm->reset;

   $controller->check_and_clear( '->reset' );

   is( ( get_field( '@_nodestate', $slurm ) )[0]->seqno_rx, 4, 'seqno_rx reset for RESETACK packet' );

   $slurm->stop;
}

# Accept reset
{
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( "\x55" . with_crc8( with_crc8( "\x01\x01" ) . "\x09" ) );
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x02\x01" ) . "\x00" ) );
   $controller->expect_sysread( "DummyFH", 8192 )
      ->remains_pending
      ->will_also_later( sub { $slurm->stop } );

   my $f = $slurm->run;
   Test::Future::Deferred->flush;

   ok( !$f->is_cancelled, '->run future is cancelled' );

   $controller->check_and_clear( 'Accepted RESET' );
}

# Lower baud rate makes longer timeouts
{
   my $slow_slurm = Device::Serial::SLuRM->new(
      fh => "SlowFH",
      baud => 38400,
   );

   $controller->use_sysread_buffer( "SlowFH" );

   $controller->expect_syswrite( "SlowFH", "\x55" . with_crc8( with_crc8( "\x01\x01" ) . "\x00" ) )
      ->will_write_sysread_buffer_later( "SlowFH", "\x55" . with_crc8( with_crc8( "\x02\x01" ) . "\x04" ) );
   $controller->expect_sleep( Test::Deep::num( 0.0052, 1E-4 ) );
   $controller->expect_syswrite( "SlowFH", "\x55" . with_crc8( with_crc8( "\x01\x01" ) . "\x00" ) );
   $controller->expect_sleep( 0.15 * 3 )
      ->remains_pending;

   await $slow_slurm->reset;

   $slow_slurm->stop;
}

done_testing;
