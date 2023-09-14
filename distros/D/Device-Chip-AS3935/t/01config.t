#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::AS3935;

my $chip = Device::Chip::AS3935->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_config
{
   $adapter->expect_write_then_read( "\x00", 4 )
      ->returns( "\x24\x22\xC2\x00" );
   $adapter->expect_write_then_read( "\x08", 1 )
      ->returns( "\x00" );

   is( await $chip->read_config,
      {
         AFE_GB       => 18,
         CL_STAT      => 1,
         LCO_FDIV     => 16,
         MASK_DIST    => '',
         MIN_NUM_LIGH => 1,
         NF_LEV       => 2,
         PWD          => "active",
         SREJ         => 2,
         WDTH         => 2,
         DISP_LCO     => '',
         DISP_SRCO    => '',
         DISP_TRCO    => '',
         TUN_CAP      => 0,

         afe        => "indoor",
         noisefloor => 62,
      },
      '$chip->read_config returns config'
   );

   $adapter->check_and_clear( '$chip->read_config' );
}

# ->change_config
{
   $adapter->expect_write( "\x00" . "\x24\x52\x42\x00" );
   $adapter->expect_write( "\x08" . "\x00" );

   await $chip->change_config( NF_LEV => 5 );

   is( await $chip->read_config,
      {
         AFE_GB       => 18,
         CL_STAT      => 1,
         LCO_FDIV     => 16,
         MASK_DIST    => '',
         MIN_NUM_LIGH => 1,
         NF_LEV       => 5,
         PWD          => "active",
         SREJ         => 2,
         WDTH         => 2,
         DISP_LCO     => '',
         DISP_SRCO    => '',
         DISP_TRCO    => '',
         TUN_CAP      => 0,

         afe        => "indoor",
         noisefloor => 112,
      },
      '$chip->read_config returns new config after ->change_config'
   );

   $adapter->check_and_clear( '$chip->change_config' );
}

done_testing;
