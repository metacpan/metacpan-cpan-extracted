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

# ->read_multisynth_config
{
   # Example bytes from Adafruit driver
   $adapter->expect_write_then_read( "\x2A", 8 )
      ->returns( "\x00\x01\x00\x01\x00\x00\x00\x00" );
   $adapter->expect_write_then_read( "\x10", 1 )
      ->returns( "\x4F" );
   $adapter->expect_write_then_read( "\xA5", 1 )
      ->returns( "\x00" );

   is( await $chip->read_multisynth_config( 0 ),
      {
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
      },
      '->read_multisynth_config yields config' );

   $adapter->check_and_clear( '->read_multisynth_config' );
}

# ->change_multisynth_config
{
   # These writes appear to get split because the caching layer doesn't bother
   # to update non-modified bytes. This might be somewhat fragile
   $adapter->expect_write( "\x2D\x17" );

   # Attempt to set ratio to 50; confirmed on real hardware
   await $chip->change_multisynth_config( 0,
      ratio_a => 50,
      ratio_b => 0,
      ratio_c => 1,
   );

   $adapter->check_and_clear( '->change_multisynth_config' );

   is( await $chip->read_multisynth_config( 0 ),
      {
         P1      => 5888,
         P2      => 0,
         P3      => 1,
         INT     => 1,
         DIVBY4  => '',
         SRC     => "PLLA",
         PHOFF   => 0,
         ratio_a => 50,
         ratio_b => 0,
         ratio_c => 1,
         ratio   => 50,
      },
      '->read_multisynth_config yields written config' );

   $adapter->check_and_clear( '->read_multisynth_config after ->change_multisynth_config' );
}

# integer ratio shortcut
{
   $adapter->expect_write( "\x2D\x12" );

   # Attempt to set ratio to 50; confirmed on real hardware
   await $chip->change_multisynth_config( 0,
      ratio   => 40,
   );

   $adapter->check_and_clear( '->change_multisynth_config whole-integer ratio' );

   is( await $chip->read_multisynth_config( 0 ),
      {
         P1      => 4608,
         P2      => 0,
         P3      => 1,
         INT     => 1,
         DIVBY4  => '',
         SRC     => "PLLA",
         PHOFF   => 0,
         ratio_a => 40,
         ratio_b => 0,
         ratio_c => 1,
         ratio   => 40,
      },
      '->read_multisynth_config yields written config' );

   $adapter->check_and_clear( '->read_multisynth_config after ->change_multisynth_config whole-integer ratio' );
}

done_testing;
