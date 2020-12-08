#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter 0.14;

use Future::AsyncAwait;

use Device::Chip::ADC121Sx;

my $chip = Device::Chip::ADC121Sx->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_adc
{
   $adapter->expect_read(2)
      ->returns( "\x01\x23" );

   is( await $chip->read_adc, 0x0123,
      '$chip->read_adc'
   );

   $adapter->check_and_clear( '$chip->read_adc' );
}

# ->read_adc_ratio
{
   $adapter->expect_read(2)
      ->returns( "\x02\x80" );

   is( await $chip->read_adc_ratio, 0.15625,
      '$chip->read_adc_ratio'
   );

   $adapter->check_and_clear( '$chip->read_adc_ratio' );
}

done_testing;
