#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::DAC7571;

my $chip = Device::Chip::DAC7571->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->write_dac
{
   $adapter->expect_write( "\x04\x00" );

   await $chip->write_dac( 1024 );

   $adapter->check_and_clear( '$chip->write_dac' );
}

# ->write_dac with powerdown
{
   $adapter->expect_write( "\x24\x00" );

   await $chip->write_dac( 1024, "100k" );

   $adapter->check_and_clear( '$chip->write_dac with powerdown' );
}

# ->write_dac_ratio
{
   $adapter->expect_write( "\x08\x00" );

   await $chip->write_dac_ratio( 0.5 );

   $adapter->check_and_clear( '$chip->write_dac_ratio' );
}

done_testing;
