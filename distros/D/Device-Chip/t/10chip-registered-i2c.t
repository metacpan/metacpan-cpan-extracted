#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait 0.47;

use Device::Chip::Base::RegisteredI2C;

my $adapter = Test::Device::Chip::Adapter->new;

{
   package TestChip;
   use base qw( Device::Chip::Base::RegisteredI2C );
}

my $chip = TestChip->new;
await $chip->mount( $adapter );

# write
{
   $adapter->expect_write( pack "C a", 123, "A" );

   await $chip->write_reg( 123, "A" );

   $adapter->check_and_clear( '->write_reg' );
}

# read
{
   $adapter->expect_write_then_read( pack( "C", 123 ), 1 )
      ->returns( "B" );

   is( await $chip->read_reg( 123, 1 ), "B", '->read_reg value' );

   $adapter->check_and_clear( '->read_reg' );
}

# cached read
{
   $adapter->expect_write_then_read( pack( "C", 2 ), 1 )
      ->returns( "\x20" );

   is( await $chip->cached_read_reg( 2, 1 ), "\x20",
         '->cached_read_reg the first time' );

   $adapter->check_and_clear( '->cached_read_reg initially' );


   is( await $chip->cached_read_reg( 2, 1 ), "\x20",
         '->cached_read_reg the second time' );

   $adapter->check_and_clear( '->cached_read_reg again' );


   $adapter->expect_write( pack( "C a", 2, "\x25" ) );

   await $chip->write_reg( 2, "\x25" );
   is_deeply( await $chip->cached_read_reg( 2, 1 ), "\x25",
         '->cached_read_reg snoops on writes' );

   $adapter->check_and_clear( '->cached_read_reg does not readdress after write snoop' );


   $adapter->expect_write_then_read( pack( "C", 2 ), 1 )
      ->returns( "\x30" );

   await $chip->read_reg( 2, 1 );
   is_deeply( await $chip->cached_read_reg( 2, 1 ), "\x30",
         '->cached_read_reg snoops on reads' );

   $adapter->check_and_clear( '->cached_read_reg does not readdress after read snoop' );
}

# cached write
{
   $adapter->expect_write( pack( "C a", 3, "\x40" ) );

   await $chip->cached_write_reg( 3, "\x40" );

   $adapter->check_and_clear( '->cached_write_reg writes on cache miss' );


   await $chip->cached_write_reg( 3, "\x40" );

   $adapter->check_and_clear( '->cached_write_reg does not write a duplicate value' );


   $adapter->expect_write( pack( "C a", 3, "\x41" ) );

   await $chip->cached_write_reg( 3, "\x41" );

   $adapter->check_and_clear( '->cached_write_reg writes a new value' );
}

# cached read multi
{
   $adapter->expect_write_then_read( pack( "C", 6 ), 2 )
      ->returns( "BC" );

   is( await $chip->cached_read_reg( 6, 2 ), "BC",
      '->cached_read_reg multi initially' );

   $adapter->check_and_clear( '->cached_read_reg multi initially' );

   $adapter->expect_write_then_read( pack( "C", 5 ), 1 )
      ->returns( "A" );
   $adapter->expect_write_then_read( pack( "C", 8 ), 2 )
      ->returns( "DE" );

   is( await $chip->cached_read_reg( 5, 5 ), "ABCDE",
      '->cached_read_reg multi again' );

   $adapter->check_and_clear( '->cached_read_reg multi again' );
}

# cached write multi
{
   $adapter->expect_write( pack( "C a*", 5, "ab" ) );
   $adapter->expect_write( pack( "C a*", 9, "e" ) );

   await $chip->cached_write_reg( 5, "abCDe" );

   $adapter->check_and_clear( '->cached_write_reg multi' );

   await $chip->cached_write_reg( 5, "abCDe" );

   $adapter->check_and_clear( '->cached_write_reg multi does not write a duplicate value' );

   is( await $chip->cached_read_reg( 5, 5 ), "abCDe",
      '->cached_read_reg multi after ->cached_write_reg' );
}

# cached write with mask
{
   $adapter->expect_write_then_read( pack( "C", 11 ), 1 )
      ->returns( "\x88" );
   $adapter->expect_write( pack( "C a*", 10, "\x5A\x58\x5A" ) );

   await $chip->cached_write_reg_masked( 10, "\x5A\x5A\x5A", "\xFF\xF0\xFF" );

   $adapter->check_and_clear( '->cached_write_reg_masked' );

   is_deeply( await $chip->cached_read_reg( 10, 3 ), "\x5A\x58\x5A",
      '->cached_read_reg reads back masked write data' );

   $adapter->check_and_clear( '->cached_read_reg after ->cached_write_reg_masked' );
}

# wide data
{
   {
      package TestChipWide;
      use base qw( Device::Chip::Base::RegisteredI2C );
      use constant REG_DATA_SIZE => 16;
   }

   my $chip = TestChipWide->new;
   await $chip->mount( $adapter );

   {
      $adapter->expect_write( pack( "C a*", 0x10, "ab" ) );

      await $chip->write_reg( 0x10, "ab" );

      $adapter->check_and_clear( '->write_reg for 16 bit data' );
   }

   {
      $adapter->expect_write_then_read( pack( "C", 0x11 ), 2 )
         ->returns( "cd" );

      is( await $chip->read_reg( 0x11, 1 ), "cd",
         '->read_reg returns value for 16 bit data' );

      $adapter->check_and_clear( '->read_reg for 16 bit data' );
   }

   {
      $adapter->expect_write( pack( "C a*", 0x12, "ef" ) );
      # no expect read
      # no expect write again

      await $chip->cached_write_reg( 0x12, "ef" );
      is( await $chip->cached_read_reg( 0x12, 1 ), "ef",
         '->cached_read_reg returns value for 16 bit data' );
      await $chip->cached_write_reg( 0x12, "ef" );

      $adapter->check_and_clear( '->cached write and read for 16 bit data' );
   }
}

done_testing;
