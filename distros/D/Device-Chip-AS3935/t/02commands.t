#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::AS3935;

my $chip = Device::Chip::AS3935->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->reset
{
   $adapter->expect_write( "\x3C" . "\x96" );

   await $chip->reset;

   $adapter->check_and_clear( '$chip->reset' );
}

# ->calibrate_rco
{
   $adapter->expect_write( "\x3D" . "\x96" );

   await $chip->calibrate_rco;

   $adapter->check_and_clear( '$chip->calibrate_rco' );
}

done_testing;
