#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::MCP23S17;

my $chip = Device::Chip::MCP23S17->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;


{
   # IODIR
   $adapter->expect_write( pack( "C C a*", 0x40, 0, "\xF0" ) );

   $chip->write_gpio( 0, 0x0f )->get;

   $adapter->check_and_clear( '->write_gpio initially' );
}

{
   $chip->write_gpio( 0, 0x0f )->get;

   $adapter->check_and_clear( '->write_gpio same values does nothing' );
}

{
   # OLAT
   $adapter->expect_write( pack( "C C a*", 0x40, 0x14, "\x0F" ) );

   $chip->write_gpio( 0xff, 0x0f )->get;

   $adapter->check_and_clear( '->write_gpio different values' );
}

{
   # OLAT
   $adapter->expect_write( pack( "C C a*", 0x40, 0x15, "\x01" ) );
   # IODIR
   $adapter->expect_write( pack( "C C a*", 0x40, 0x01, "\xFE" ) );

   $chip->write_gpio( 0xffff, (1<<8) )->get;

   $adapter->check_and_clear( '->write_gpio to a new pin' );
}

done_testing;
