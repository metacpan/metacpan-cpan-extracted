#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter 0.05;  # ->expect_assert_ss, etc..

use Device::Chip::SDCard;

my $chip = Device::Chip::SDCard->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

{
   $adapter->expect_assert_ss;
   $adapter->expect_write_no_ss( "\x51\x00\x00\x00\x00\xFF\xFF" );
   $adapter->expect_readwrite_no_ss( "\xFF" x 8 )
      # Slow reply
      ->returns( "\xFF\x00\xFF\xFF\xFF\xFF\xFF\xFF" );
   $adapter->expect_readwrite_no_ss( "\xFF" x 16 )
      ->returns( "\xFE" . "BLOCK" . "\0" x 10 );     # first 15 bytes
   $adapter->expect_readwrite_no_ss( "\xFF" x 499 )
      ->returns( "\0" x 499 ); # remaining 512-15 = 497 bytes + 2 CRC
   $adapter->expect_release_ss;

   is( $chip->read_block( 0 )->get, "BLOCK" . "\0" x ( 512 - 5 ),
      '$chip->read_block returns bytes' );

   $adapter->check_and_clear( '$chip->read_block' );
}

{
   $adapter->expect_assert_ss;
   $adapter->expect_write_no_ss( "\x51\x00\x00\x00\x00\xFF\xFF" );
   $adapter->expect_readwrite_no_ss( "\xFF" x 8 )
      # Really slow reply
      ->returns( "\xFF\x00\xFF\xFF\xFF\xFF\xFF\xFF" );
   $adapter->expect_readwrite_no_ss( "\xFF" x 16 )
      ->returns( "\xFF" x 16 );     # stall
   $adapter->expect_readwrite_no_ss( "\xFF" x 16 )
      ->returns( "\xFF" x 8 . "\xFE" . "BLOCK" . "\0" x 2 );     # first 7 bytes
   $adapter->expect_readwrite_no_ss( "\xFF" x 507 )
      ->returns( "\0" x 507 ); # remaining 512-7 = 505 bytes + 2 CRC
   $adapter->expect_release_ss;

   is( $chip->read_block( 0 )->get, "BLOCK" . "\0" x ( 512 - 5 ),
      '$chip->read_block returns bytes' );

   $adapter->check_and_clear( '$chip->read_block with really slow reply' );
}

{
   $adapter->expect_assert_ss;
   $adapter->expect_write_no_ss( "\x51\x00\x00\x00\x00\xFF\xFF" );
   $adapter->expect_readwrite_no_ss( "\xFF" x 8 )
      # Fast reply
      ->returns( "\xFF\x00\xFF\xFEBLOC" );           # first 4 bytes
   $adapter->expect_readwrite_no_ss( "\xFF" x 510 )
      ->returns( "K" . "\0" x 509 ); # remaining 512-4 = 508 bytes + 2 CRC
   $adapter->expect_release_ss;

   is( $chip->read_block( 0 )->get, "BLOCK" . "\0" x ( 512 - 5 ),
      '$chip->read_block returns bytes' );

   $adapter->check_and_clear( '$chip->read_block' );
}

done_testing;
