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

# ->write_bcd
{
   $adapter->expect_write( "\x09\x01" ); # REG_DECODE
   $adapter->expect_write( "\x01\x01" ); # REG_DIGIT+0
   $adapter->expect_write( "\x09\x03" ); # REG_DECODE
   $adapter->expect_write( "\x02\x05" ); # REG_DIGIT+0

   await $chip->write_bcd( 0, 1 );
   await $chip->write_bcd( 1, 5 );

   # No REG_DECODE
   $adapter->expect_write( "\x01\x02" ); # REG_DIGIT+1

   await $chip->write_bcd( 0, 2 );

   $adapter->check_and_clear( '->write_bcd' );
}

# ->write_raw
{
   $adapter->expect_write( "\x09\x02" ); # REG_DECODE
   $adapter->expect_write( "\x01\xF0" ); # REG_DIGIT+0
   $adapter->expect_write( "\x09\x00" ); # REG_DECODE
   $adapter->expect_write( "\x02\x55" ); # REG_DIGIT+1

   await $chip->write_raw( 0, 0xF0 );
   await $chip->write_raw( 1, 0x55 );

   # No REG_DECODE
   $adapter->expect_write( "\x01\xF5" ); # REG_DIGIT+0

   await $chip->write_raw( 0, 0xF5 );

   $adapter->check_and_clear( '->write_raw' );
}

# ->write_hex
{
   $adapter->expect_write( "\x01\x5B" ); # REG_DIGIT+0
   $adapter->expect_write( "\x02\x70" ); # REG_DIGIT+1

   await $chip->write_hex( 0, 5 );
   await $chip->write_hex( 1, 7 );

   $adapter->expect_write( "\x01\x3D" ); # REG_DIGIT+0

   await $chip->write_hex( 0, 'D' );

   $adapter->check_and_clear( '->write_hex' );
}

done_testing;
