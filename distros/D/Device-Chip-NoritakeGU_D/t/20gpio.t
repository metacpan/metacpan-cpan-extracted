#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

# writes operate directly over UART so this is the easiest to unit test
use Device::Chip::NoritakeGU_D;

my $chip = Device::Chip::NoritakeGU_D->new( interface => "UART" );

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

{
   $adapter->expect_write( "\x1F\x28\x70\x01\x00\x03" );

   await $chip->set_gpio_direction( 0x03 );

   $adapter->check_and_clear( '$chip->set_gpio_direction' );
}

{
   $adapter->expect_write( "\x1F\x28\x70\x10\x00\x02" );

   await $chip->write_gpio( 0x02 );

   $adapter->check_and_clear( '$chip->write_gpio' );
}

{
   $adapter->expect_write( "\x1F\x28\x70\x20\x00" );
   $adapter->expect_read( 4 )
      ->returns( "\x28\x70\x20\x08" );

   is( await $chip->read_gpio, 0x08,
      '$chip->read_gpio returns GPIO' );

   $adapter->check_and_clear( '$chip->read_gpio' );
}

done_testing;
