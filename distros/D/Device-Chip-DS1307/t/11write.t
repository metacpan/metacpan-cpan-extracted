#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::DS1307;

my $chip = Device::Chip::DS1307->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->write_time
{
   $adapter->expect_write( "\x00" . "\x56\x34\x12\x00\x07\x08\x90" );

   await $chip->write_time( 56, 34, 12, 7, 7, 190, 0 );

   $adapter->check_and_clear( '$chip->read_time' );
}

done_testing;
