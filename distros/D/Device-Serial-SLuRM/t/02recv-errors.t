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

# We'll test a number of scenarios by attempting to send two packets, the
# first having some sort of corruption, and demonstrate that the second
# still arrives OK
my $emptybytes = "\x55" . with_crc8( with_crc8( "\x1F\x00" ) );
my $OKbytes    = "\x55" . with_crc8( with_crc8( "\x11\x02" ) . "OK" );
my $expect = [ 0x11, "OK" ];

# Missing SYNC byte
{
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done(
         with_crc8( with_crc8( "\x10\x03" ) . "BAD" ) .
         $OKbytes
      );

   is_deeply( [ await $slurm->recv_packet ], $expect,
      'Packet received by ->recv_packet after missing SYNC byte' );

   $controller->check_and_clear( '->recv_packet after missing SYNC byte' );
}

# Corrupted SYNC byte
{
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done(
         "\x56" . with_crc8( with_crc8( "\x10\x03" ) . "BAD" ) .
         $OKbytes
      );

   is_deeply( [ await $slurm->recv_packet ], $expect,
      'Packet received by ->recv_packet after corrupted SYNC byte' );

   $controller->check_and_clear( '->recv_packet after corrupted SYNC byte' );
}

# Corrupted header CRC
{
   my $badbytes = "\x55" . with_crc8( with_crc8( "\x10\x03" ) . "BAD" );
   substr( $badbytes, 1, 1 ) ^= "\x01";

   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( $badbytes . $OKbytes );

   is_deeply( [ await $slurm->recv_packet ], $expect,
      'Packet received by ->recv_packet after corrupted header' );

   $controller->check_and_clear( '->recv_packet after corrupted header' );
}

# Corrupted payload CRC
{
   my $badbytes = "\x55" . with_crc8( with_crc8( "\x10\x03" ) . "BAD" );
   substr( $badbytes, length($badbytes) - 1, 1 ) ^= "\x01";

   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( $badbytes . $OKbytes );

   is_deeply( [ await $slurm->recv_packet ], $expect,
      'Packet received by ->recv_packet after corrupted payload CRC' );

   $controller->check_and_clear( '->recv_packet after corrupted payload CRC' );
}

# Noisy byte in between packets
{
   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( $emptybytes . "X" . $OKbytes );

   is_deeply( [ await $slurm->recv_packet ], [ 0x1F, "" ],
      'First packet received before spurious noise byte' );
   is_deeply( [ await $slurm->recv_packet ], $expect,
      'Packet received by ->recv_packet after spurious noise byte' );

   $controller->check_and_clear( '->recv_packet after spurious noise byte' );
}

# Byte missing in payload
{
   my $badbytes = "\x55" . with_crc8( with_crc8( "\x10\x03" ) . "BAD" );
   substr( $badbytes, 6, 1 ) = "";

   $controller->expect_sysread( "DummyFH", 8192 )
      ->will_done( $badbytes . $OKbytes );

   is_deeply( [ await $slurm->recv_packet ], $expect,
      'Packet received by ->recv_packet after missing payload byte' );

   $controller->check_and_clear( '->recv_packet after missing payload byte' );
}

done_testing;
