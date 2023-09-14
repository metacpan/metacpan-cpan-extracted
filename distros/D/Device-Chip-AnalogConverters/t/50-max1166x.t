#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter 0.14;

use Future::AsyncAwait;

use Device::Chip::MAX1166x;

my $chip = Device::Chip::MAX1166x->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_adc
{
   $adapter->expect_read(2)
      ->returns( "\x04\x8C" );

   is( await $chip->read_adc, 0x048C,
      '$chip->read_adc'
   );

   $adapter->check_and_clear( '$chip->read_adc' );
}

# ->read_adc_ratio
{
   $adapter->expect_read(2)
      ->returns( "\x0A\x00" );

   is( await $chip->read_adc_ratio, 0.15625,
      '$chip->read_adc_ratio'
   );

   $adapter->check_and_clear( '$chip->read_adc_ratio' );
}

done_testing;
