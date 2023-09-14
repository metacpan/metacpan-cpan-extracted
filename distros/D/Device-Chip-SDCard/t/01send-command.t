#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::SDCard;

my $chip = Device::Chip::SDCard->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

{
   $adapter->expect_readwrite( "\x54\0\0\1\0\x95" . "\xFF" x 8 )
      ->returns( "\xFF\xFF\xFF\xFF\xFF\xFF\xFF" . "\x01" . "\xFF" x 7 );

   is( await $chip->send_command( 20, 0x100 ), 1,
      '$chip->send_command returns response' );

   $adapter->check_and_clear( '$chip->send_command' );
}

done_testing;
