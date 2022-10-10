#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Future::IO 0.05;

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

# Initiate reset
{
   $controller->use_sysread_buffer( "DummyFH" );

   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x01\x01" ) . "\x00" ) );
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x01\x01" ) . "\x00" ) );
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( "\x55" . with_crc8( with_crc8( "\x02\x01" ) . "\x04" ) );

   await $slurm->reset;

   $controller->check_and_clear( '->reset' );

   is( $slurm->_seqno_rx, 4, 'seqno_rx reset for RESETACK packet' );

   $slurm->stop;
}

# Accept reset
{
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( "\x55" . with_crc8( with_crc8( "\x01\x01" ) . "\x09" ) );
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x02\x01" ) . "\x00" ) );
   $controller->expect_sysread( "DummyFH", 8192 )
      ->remains_pending
      ->will_also( sub { $slurm->stop } );

   $slurm->_start->await; # it gets cancelled

   $controller->check_and_clear( 'Accepted RESET' );
}

done_testing;
