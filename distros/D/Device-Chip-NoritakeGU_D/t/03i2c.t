#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::NoritakeGU_D;

my $chip = Device::Chip::NoritakeGU_D->new( interface => "I2C" );

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->text
{
   $adapter->expect_write( "\x41\x42\x43" );

   await $chip->text( "ABC" );

   $adapter->check_and_clear( '$chip->text' );
}

# ->clear
{
   $adapter->expect_write( "\x0C" );

   await $chip->clear;

   $adapter->check_and_clear( '$chip->clear' );
}

# internal ->read method
{
   $adapter->expect_read( 2 )
      ->returns( "\x44\x45" );

   is( await $chip->read( 2 ), "DE", '$chip->read returns data' );

   $adapter->check_and_clear( '$chip->read' );
}

done_testing;
