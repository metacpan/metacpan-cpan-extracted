#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::LTC2400;

my $chip = Device::Chip::LTC2400->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_adc
{
   $adapter->expect_readwrite( "\x00\x00\x00\x00" )
      ->returns( "\x20\x12\x34\x50" );

   is( await $chip->read_adc,
      {
         EOC => 1,
         EXR => '',
         SIG => 1,
         VALUE => 0x012345,
      },
      '$chip->read_adc'
   );

   $adapter->check_and_clear( '$chip->read_adc' );
}

done_testing;
