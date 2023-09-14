#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::TSL256x;

my $chip = Device::Chip::TSL256x->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

{
   $adapter->expect_write( "\x80\x03" );

   await $chip->power(1);

   $adapter->check_and_clear( '$chip->power' );
}

done_testing;
