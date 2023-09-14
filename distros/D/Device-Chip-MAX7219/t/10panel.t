#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::MAX7219Panel;

my $chip = Device::Chip::MAX7219Panel->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

is( $chip->rows, 8, '$chip->rows' );
is( $chip->columns, 32, '$chip->columns' );

# ->init
{
   $adapter->expect_write( "\x0B\x07\x0B\x07\x0B\x07\x0B\x07" ); # REG_LIMIT
   $adapter->expect_write( "\x09\x00\x09\x00\x09\x00\x09\x00" ); # REG_DECODE

   await $chip->init;

   $adapter->check_and_clear( '->init' );

}
# ->intensity
{
   $adapter->expect_write( "\x0A\x06\x0A\x06\x0A\x06\x0A\x06" ); # REG_INTENSITY

   await $chip->intensity( 6 );

   $adapter->check_and_clear( '->intensity' );
}

# ->displaytest
{
   $adapter->expect_write( "\x0F\x01\x0F\x01\x0F\x01\x0F\x01" ); # REG_DTEST

   await $chip->displaytest( 1 );

   $adapter->check_and_clear( '->displaytest' );
}

# ->shutdown
{
   $adapter->expect_write( "\x0C\x00\x0C\x00\x0C\x00\x0C\x00" ); # REG_DTEST

   await $chip->shutdown;

   $adapter->check_and_clear( '->shutdown' );
}

done_testing;
