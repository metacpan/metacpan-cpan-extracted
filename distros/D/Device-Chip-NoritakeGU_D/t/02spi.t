#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::NoritakeGU_D;

my $chip = Device::Chip::NoritakeGU_D->new( interface => "SPI" );

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->text
{
   $adapter->expect_write( "\x44" . "\x41\x42\x43" );

   await $chip->text( "ABC" );

   $adapter->check_and_clear( '$chip->text' );
}

# ->clear
{
   $adapter->expect_write( "\x44" . "\x0C" );

   await $chip->clear;

   $adapter->check_and_clear( '$chip->clear' );
}

# internal ->read method
{
   $adapter->expect_write_then_read( "\x58", 2 )
      ->returns( "\x58\x02" );

   $adapter->expect_write_then_read( "\x54", 4 )
      ->returns( "\x54\x00\x44\x45" );

   is( await $chip->read( 2 ), "DE", '$chip->read returns data' );

   $adapter->check_and_clear( '$chip->read' );
}

done_testing;
