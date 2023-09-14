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

# ->read_config
{
   $adapter->expect_write_then_read( "\xB7", 1 )
      ->returns( "\xC0" );
   $adapter->expect_write_then_read( "\xBB", 1 )
      ->returns( "\x00" );

   is( await $chip->read_config,
      {
         XTAL_CL   => "10pF",
         CLKIN_FANOUT => '',
         XO_FANOUT    => '',
         MS_FANOUT    => '',
      },
      '->read_config yields config' );

   $adapter->check_and_clear( '->read_config' );
}

# ->change_config
{
   $adapter->expect_write( "\xBB\x40" );

   await $chip->change_config( XO_FANOUT => 1 );

   $adapter->check_and_clear( '->change_config' );
}

done_testing;
