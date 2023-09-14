#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::MCP23S17;

my $chip = Device::Chip::MCP23S17->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

{
   # IODIR
   $adapter->expect_write( pack( "C C a*", 0x40, 0, "\xF0" ) );

   await $chip->write_gpio( 0, 0x0f );

   $adapter->check_and_clear( '->write_gpio initially' );
}

{
   await $chip->write_gpio( 0, 0x0f );

   $adapter->check_and_clear( '->write_gpio same values does nothing' );
}

{
   # OLAT
   $adapter->expect_write( pack( "C C a*", 0x40, 0x14, "\x0F" ) );

   await $chip->write_gpio( 0xff, 0x0f );

   $adapter->check_and_clear( '->write_gpio different values' );
}

{
   # OLAT
   $adapter->expect_write( pack( "C C a*", 0x40, 0x15, "\x01" ) );
   # IODIR
   $adapter->expect_write( pack( "C C a*", 0x40, 0x01, "\xFE" ) );

   await $chip->write_gpio( 0xffff, (1<<8) );

   $adapter->check_and_clear( '->write_gpio to a new pin' );
}

done_testing;
