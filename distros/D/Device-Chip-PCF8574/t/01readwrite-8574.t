#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter 0.08;  # ->read

use Future::AsyncAwait;

use Device::Chip::PCF8574;

my $chip = Device::Chip::PCF8574->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->write
{
   $adapter->expect_write( "\x55" );

   await $chip->write( 0x55 );

   $adapter->check_and_clear( '$chip->write' );
}

# ->read
{
   $adapter->expect_read( 1 )->returns( "\xAA" );

   is( await $chip->read, 0xAA, '$chip->read returns value' );

   $adapter->check_and_clear( '$chip->read' );
}

done_testing;
