#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter 0.08;  # ->read

use Future::AsyncAwait;

use Device::Chip::PCF8575;

my $chip = Device::Chip::PCF8575->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->write
{
   $adapter->expect_write( "\x34\x12" );

   await $chip->write( 0x1234 );

   $adapter->check_and_clear( '$chip->write' );
}

# ->read
{
   $adapter->expect_read( 2 )->returns( "\xAB\xCD" );

   is( await $chip->read, 0xCDAB, '$chip->read returns value' );

   $adapter->check_and_clear( '$chip->read' );
}

done_testing;
