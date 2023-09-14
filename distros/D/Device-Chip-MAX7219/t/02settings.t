#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::MAX7219;

my $chip = Device::Chip::MAX7219->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->intensity
{
   $adapter->expect_write( "\x0A\x06" ); # REG_INTENSITY

   await $chip->intensity( 6 );

   $adapter->check_and_clear( '->intensity' );
}

# ->limit
{
   $adapter->expect_write( "\x0B\x03" ); # REG_LIMIT

   await $chip->limit( 4 );

   $adapter->check_and_clear( '->limit' );
}

# ->shutdown
{
   $adapter->expect_write( "\x0C\x00" ); # REG_SHUTDOWN

   await $chip->shutdown( 1 );

   $adapter->check_and_clear( '->shutdown' );
}

# ->displaytest
{
   $adapter->expect_write( "\x0F\x01" ); # REG_DTEST

   await $chip->displaytest( 1 );

   $adapter->check_and_clear( '->displaytest' );
}

done_testing;
