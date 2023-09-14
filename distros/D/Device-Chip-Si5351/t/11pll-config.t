#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::Si5351;

my $chip = Device::Chip::Si5351->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_pll_config
{
   # Example bytes from Adafruit driver
   $adapter->expect_write_then_read( "\x1A", 8 )
      ->returns( "\x00\x05\x00\x0C\x66\x00\x00\x02" );
   $adapter->expect_write_then_read( "\x0F", 1 )
      ->returns( "\x00" );

   is( await $chip->read_pll_config( "A" ),
      {
         P1  => 3174,
         P2  => 2,
         P3  => 5,
         SRC => "XTAL",
         # inferred
         ratio_a => 28,
         ratio_b => 4,
         ratio_c => 5,
         ratio   => 28.8,
      },
      '->read_pll_config yields config' );

   $adapter->check_and_clear( '->read_pll_config' );
}

# ->change_pll_config
{
   # These writes appear to get split because the caching layer doesn't bother
   # to update non-modified bytes. This might be somewhat fragile
   $adapter->expect_write( "\x1A\x02\x71" );
   $adapter->expect_write( "\x1E\xBE" );
   $adapter->expect_write( "\x20\x02\x22" );

   $adapter->expect_write( "\xB1\xAC" );  # PLL_RESET

   # Attempt to set ratio to 28 + 307/625; confirmed on real hardware
   await $chip->change_pll_config( "A",
      ratio_a => 29,
      ratio_b => 307,
      ratio_c => 625,
   );

   $adapter->check_and_clear( '->change_pll_config' );

   is( await $chip->read_pll_config( "A" ),
      {
         P1      => 3262,
         P2      => 546,
         P3      => 625,
         SRC     => "XTAL",
         ratio_a => 29,
         ratio_b => 307,
         ratio_c => 625,
         ratio   => 29.4912,
      },
      '->read_pll_config yields written config' );

   $adapter->check_and_clear( '->read_pll_config after ->change_pll_config' );
}

# integer ratio shortcut
{
   $adapter->expect_write( "\x1A\x00\x01" );
   $adapter->expect_write( "\x1D\x0D\x00" );
   $adapter->expect_write( "\x20\x00\x00" );

   $adapter->expect_write( "\xB1\xAC" );  # PLL_RESET

   await $chip->change_pll_config( "A",
      ratio => 30,
   );

   $adapter->check_and_clear( '->change_pll_config whole-integer ratio' );

   is( await $chip->read_pll_config( "A" ),
      {
         P1      => 3328,
         P2      => 0,
         P3      => 1,
         SRC     => "XTAL",
         ratio_a => 30,
         ratio_b => 0,
         ratio_c => 1,
         ratio   => 30,
      },
      '->read_pll_config yields written config' );

   $adapter->check_and_clear( '->read_pll_config after ->change_pll_config whole-integer ratio' );
}

done_testing;
