#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::Base::RegisteredI2C;

my $adapter = Test::Device::Chip::Adapter->new;

{
   package TestChip;
   use base qw( Device::Chip::Base::RegisteredI2C );
}

my $chip = TestChip->new;
$chip->mount( $adapter )->get;

# write
{
   $adapter->expect_write( pack "C a", 123, "A" );

   $chip->write_reg( 123, "A" )->get;

   $adapter->check_and_clear( '->write_reg' );
}

# read
{
   $adapter->expect_write_then_read( pack( "C", 123 ), 1 )
      ->returns( "B" );

   is( $chip->read_reg( 123, 1 )->get, "B", '->read_reg value' );

   $adapter->check_and_clear( '->read_reg' );
}

# cached read
{
   $adapter->expect_write_then_read( pack( "C", 2 ), 1 )
      ->returns( "\x20" );

   is( $chip->cached_read_reg( 2, 1 )->get, "\x20",
         '->cached_read_reg the first time' );

   $adapter->check_and_clear( '->cached_read_reg initially' );


   is( $chip->cached_read_reg( 2, 1 )->get, "\x20",
         '->cached_read_reg the second time' );

   $adapter->check_and_clear( '->cached_read_reg again' );


   $adapter->expect_write( pack( "C a", 2, "\x25" ) );

   $chip->write_reg( 2, "\x25" )->get;
   is_deeply( $chip->cached_read_reg( 2, 1 )->get, "\x25",
         '->cached_read_reg snoops on writes' );

   $adapter->check_and_clear( '->cached_read_reg does not readdress after write snoop' );


   $adapter->expect_write_then_read( pack( "C", 2 ), 1 )
      ->returns( "\x30" );

   $chip->read_reg( 2, 1 )->get;
   is_deeply( $chip->cached_read_reg( 2, 1 )->get, "\x30",
         '->cached_read_reg snoops on reads' );

   $adapter->check_and_clear( '->cached_read_reg does not readdress after read snoop' );
}

# cached write
{
   $adapter->expect_write( pack( "C a", 3, "\x40" ) );

   $chip->cached_write_reg( 3, "\x40" )->get;

   $adapter->check_and_clear( '->cached_write_reg writes on cache miss' );


   $chip->cached_write_reg( 3, "\x40" )->get;

   $adapter->check_and_clear( '->cached_write_reg does not write a duplicate value' );


   $adapter->expect_write( pack( "C a", 3, "\x41" ) );

   $chip->cached_write_reg( 3, "\x41" )->get;

   $adapter->check_and_clear( '->cached_write_reg writes a new value' );
}

# cached read multi
{
   $adapter->expect_write_then_read( pack( "C", 6 ), 2 )
      ->returns( "BC" );

   is( $chip->cached_read_reg( 6, 2 )->get, "BC",
      '->cached_read_reg multi initially' );

   $adapter->check_and_clear( '->cached_read_reg multi initially' );

   $adapter->expect_write_then_read( pack( "C", 5 ), 1 )
      ->returns( "A" );
   $adapter->expect_write_then_read( pack( "C", 8 ), 2 )
      ->returns( "DE" );

   is( $chip->cached_read_reg( 5, 5 )->get, "ABCDE",
      '->cached_read_reg multi again' );

   $adapter->check_and_clear( '->cached_read_reg multi again' );
}

# cached write multi
{
   $adapter->expect_write( pack( "C a*", 5, "ab" ) );
   $adapter->expect_write( pack( "C a*", 9, "e" ) );

   $chip->cached_write_reg( 5, "abCDe" )->get;

   $adapter->check_and_clear( '->cached_write_reg multi' );

   $chip->cached_write_reg( 5, "abCDe" )->get;

   $adapter->check_and_clear( '->cached_write_reg multi does not write a duplicate value' );

   is( $chip->cached_read_reg( 5, 5 )->get, "abCDe",
      '->cached_read_reg multi after ->cached_write_reg' );
}

# wide data
{
   {
      package TestChipWide;
      use base qw( Device::Chip::Base::RegisteredI2C );
      use constant REG_DATA_SIZE => 16;
   }

   my $chip = TestChipWide->new;
   $chip->mount( $adapter )->get;

   {
      $adapter->expect_write( pack( "C a*", 0x10, "ab" ) );

      $chip->write_reg( 0x10, "ab" )->get;

      $adapter->check_and_clear( '->write_reg for 16 bit data' );
   }

   {
      $adapter->expect_write_then_read( pack( "C", 0x11 ), 2 )
         ->returns( "cd" );

      is( $chip->read_reg( 0x11, 1 )->get, "cd",
         '->read_reg returns value for 16 bit data' );

      $adapter->check_and_clear( '->read_reg for 16 bit data' );
   }

   {
      $adapter->expect_write( pack( "C a*", 0x12, "ef" ) );
      # no expect read
      # no expect write again

      $chip->cached_write_reg( 0x12, "ef" )->get;
      is( $chip->cached_read_reg( 0x12, 1 )->get, "ef",
         '->cached_read_reg returns value for 16 bit data' );
      $chip->cached_write_reg( 0x12, "ef" )->get;

      $adapter->check_and_clear( '->cached write and read for 16 bit data' );
   }
}

done_testing;
