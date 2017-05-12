#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::SDCard;

my $chip = Device::Chip::SDCard->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

{
   $adapter->expect_readwrite( "\x54\0\0\1\0\x95" . "\xFF" x 8 )
      ->returns( "\xFF\xFF\xFF\xFF\xFF\xFF\xFF" . "\x01" . "\xFF" x 7 );

   is( $chip->send_command( 20, 0x100 )->get, 1,
      '$chip->send_command returns response' );

   $adapter->check_and_clear( '$chip->send_command' );
}

done_testing;
