#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Future::IO;

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

# recv
{
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( "\x55" . with_crc8( with_crc8( "\x10\x03" ) . "ABC" ) );

   is_deeply( [ await $slurm->recv_packet ], [ 0x10, "ABC" ],
      'One packet received by ->recv_packet' );

   $controller->check_and_clear( '->recv_packet' );

   # Two packets combined

   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( "\x55" . with_crc8( with_crc8( "\x11\x01" ) . "1" ) .
                 "\x55" . with_crc8( with_crc8( "\x12\x01" ) . "2" ) );

   is_deeply( [ await $slurm->recv_packet ], [ 0x11, "1" ],
      'First of two packets received by ->recv_packet' );
   is_deeply( [ await $slurm->recv_packet ], [ 0x12, "2" ],
      'Second of two packets received by ->recv_packet' );

   $controller->check_and_clear( '->recv_packet combined' );

   # One packet split across two writes
   my $bytes = "\x55" . with_crc8( with_crc8( "\x13\x05" ) . "SPLIT" );

   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( substr $bytes, 0, 4 );
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( substr $bytes, 4 );

   is_deeply( [ await $slurm->recv_packet ], [ 0x13, "SPLIT" ],
      'Packets received by ->recv_packet for split write' );

   $controller->check_and_clear( '->recv_packet split' );
}

# send
{
   $controller->expect_syswrite( "DummyFH", "\x55" . with_crc8( with_crc8( "\x18\x03" ) . "DEF" ) );

   await $slurm->send_packet( 0x18, "DEF" );

   $controller->check_and_clear( '->send_packet' );
}

done_testing;
