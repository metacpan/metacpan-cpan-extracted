#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::BV4243;

my $chip = Device::Chip::BV4243->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

{
   $adapter->expect_write( "\x06\x64" );

   await $chip->beep( 100 );

   $adapter->check_and_clear( '->beep' );
}

{
   $adapter->expect_write( "\x15" );

   await $chip->sleep;

   $adapter->check_and_clear( '->sleep' );
}

{
   $adapter->expect_write( "\x95" );

   await $chip->reset;

   $adapter->check_and_clear( '->reset' );
}

{
   $adapter->expect_write( "\x14" );

   await $chip->eeprom_reset;

   $adapter->check_and_clear( '->eeprom_reset' );
}

{
   $adapter->expect_write_then_read( "\x90\x12", 1 )
      ->returns( "\x34" );

   is( await $chip->eeprom_read( 0x12 ), 0x34,
      '->eeprom_read yields byte' );

   $adapter->check_and_clear( '->eeprom_read' );
}

{
   $adapter->expect_write( "\x91\x12\x56" );

   await $chip->eeprom_write( 0x12, 0x56 );

   $adapter->check_and_clear( '->eeprom_write' );
}

done_testing;
