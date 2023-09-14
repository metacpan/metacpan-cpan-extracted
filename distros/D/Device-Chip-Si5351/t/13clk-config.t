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

# ->read_clk_config
{
   $adapter->expect_write_then_read( "\x10", 1 )
      ->returns( "\x00" );
   $adapter->expect_write_then_read( "\x2C", 1 )
      ->returns( "\x00" );
   $adapter->expect_write_then_read( "\x03", 1 )
      ->returns( "\x00" );

   is( await $chip->read_clk_config( 0 ),
      {
         IDRV => "2mA",
         SRC  => "XTAL",
         INV  => '',
         PDN  => '',
         DIV  => 1,
         OE   => 1,
      },
      '->read_clk_config yields config' );

   $adapter->check_and_clear( '->read_clk_config' );
}

# ->change_clk_config
{
   $adapter->expect_write( "\x2C\x20" );

   await $chip->change_clk_config( 0, SRC => "XTAL", DIV => 4 );

   $adapter->check_and_clear( '->change_clk_config' );
}

done_testing;
