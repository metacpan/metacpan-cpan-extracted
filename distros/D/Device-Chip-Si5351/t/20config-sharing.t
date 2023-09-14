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

# Certain registers are shared by both Multisynth and Clock output units. This
# test ensures that updates to either don't overwrite settings of the other

my %MS0_CONFIG = (
   P1     => 256,
   P2     => 0,
   P3     => 1,
   INT    => 1,
   DIVBY4 => '',
   SRC    => "PLLA",
   PHOFF  => 0,
   # inferred
   ratio_a => 6,
   ratio_b => 0,
   ratio_c => 1,
   ratio   => 6,
);

my %CLK0_CONFIG = (
   IDRV => "8mA",
   SRC  => "MSn",
   INV  => '',
   PDN  => '',
   DIV  => 2,
   OE   => 1,
);

# initial setup
{
   $adapter->expect_write_then_read( "\x2A", 8 )
      ->returns( "\x00\x01\x10\x01\x00\x00\x00\x00" );
   $adapter->expect_write_then_read( "\x10", 1 )
      ->returns( "\x4F" );
   $adapter->expect_write_then_read( "\xA5", 1 )
      ->returns( "\x00" );
   $adapter->expect_write_then_read( "\x03", 1 )
      ->returns( "\x00" );

   is( await $chip->read_multisynth_config( 0 ), \%MS0_CONFIG,
      '->read_multisynth_config yields initial config' );

   is( await $chip->read_clk_config( 0 ), \%CLK0_CONFIG,
      '->read_clk_config yields initial config' );

   $adapter->check_and_clear( 'Initial setup' );
}

# REG_CLKnCTRL stores MS's SRC and CLK's IDRV
{
   $adapter->expect_write( "\x10\x6F" );

   await $chip->change_multisynth_config( 0, SRC => ($MS0_CONFIG{SRC} = "PLLB") );

   is( await $chip->read_multisynth_config( 0 ), \%MS0_CONFIG,
      '->read_multisynth_config yields new config' );

   is( await $chip->read_clk_config( 0 ), \%CLK0_CONFIG,
      '->read_clk_config yields unchanged config' );

   $adapter->check_and_clear( '->change_multisynth_config' );


   $adapter->expect_write( "\x10\x6D" );

   await $chip->change_clk_config( 0, IDRV => ($CLK0_CONFIG{IDRV} = "4mA") );

   is( await $chip->read_multisynth_config( 0 ), \%MS0_CONFIG,
      '->read_multisynth_config yields unchanged config' );

   is( await $chip->read_clk_config( 0 ), \%CLK0_CONFIG,
      '->read_clk_config yields new config' );

   $adapter->check_and_clear( '->change_clk_config' );
}

# REG_MSn_BASE+2 stores MS's P1 and CLK's DIV
{
   # Set a really unrealistically large number as P1 to make the top bits set

   $adapter->expect_write( "\x2C\x12\x67" );

   await $chip->change_multisynth_config( 0, ratio_a => 1234, ratio_b => 0, ratio_c => 1 );
   $MS0_CONFIG{P1}      = 157440;
   $MS0_CONFIG{ratio_a} = 1234;
   $MS0_CONFIG{ratio}   = 1234;

   is( await $chip->read_multisynth_config( 0 ), \%MS0_CONFIG,
      '->read_multisynth_config yields new config' );

   is( await $chip->read_clk_config( 0 ), \%CLK0_CONFIG,
      '->read_clk_config yields unchanged config' );

   $adapter->check_and_clear( '->change_multisynth_config' );


   $adapter->expect_write( "\x2C\x32" );

   await $chip->change_clk_config( 0, DIV => ($CLK0_CONFIG{DIV} = 8) );

   is( await $chip->read_multisynth_config( 0 ), \%MS0_CONFIG,
      '->read_multisynth_config yields unchanged config' );

   is( await $chip->read_clk_config( 0 ), \%CLK0_CONFIG,
      '->read_clk_config yields new config' );

   $adapter->check_and_clear( '->change_clk_config' );
}

done_testing;
