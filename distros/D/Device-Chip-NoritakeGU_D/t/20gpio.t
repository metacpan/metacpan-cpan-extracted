#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

# writes operate directly over UART so this is the easiest to unit test
use Device::Chip::NoritakeGU_D;

my $chip = Device::Chip::NoritakeGU_D->new( interface => "UART" );

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

{
   $adapter->expect_write( "\x1F\x28\x70\x01\x00\x03" );

   $chip->set_gpio_direction( 0x03 )->get;

   $adapter->check_and_clear( '$chip->set_gpio_direction' );
}

{
   $adapter->expect_write( "\x1F\x28\x70\x10\x00\x02" );

   $chip->write_gpio( 0x02 )->get;

   $adapter->check_and_clear( '$chip->write_gpio' );
}

{
   $adapter->expect_write( "\x1F\x28\x70\x20\x00" );
   $adapter->expect_read( 4 )
      ->returns( "\x28\x70\x20\x08" );

   is( $chip->read_gpio->get, 0x08,
      '$chip->read_gpio returns GPIO' );

   $adapter->check_and_clear( '$chip->read_gpio' );
}

done_testing;
