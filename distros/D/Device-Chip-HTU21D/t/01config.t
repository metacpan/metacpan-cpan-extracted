#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::HTU21D;

my $chip = Device::Chip::HTU21D->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_config
{
   $adapter->expect_write_then_read( "\xE7", 1 )
      ->returns( "\x02" );

   is_deeply( await $chip->read_config,
      {
         ENDOFBATT  => !!0,
         HEATER     => !!0,
         OTPDISABLE => 1,
         RES        => "12/14",
      },
      '$chip->read_config'
   );

   $adapter->check_and_clear( '$chip->read_config' );
}

# ->change_config
{
   $adapter->expect_write_then_read( "\xE7", 1 )
      ->returns( "\x02" );
   $adapter->expect_write( "\xE6\x06" );

   await $chip->change_config( HEATER => 1 );

   $adapter->check_and_clear( '$chip->change_config' );
}

# ->change_config new resolution
{
   $adapter->expect_write_then_read( "\xE7", 1 )
      ->returns( "\x02" );
   $adapter->expect_write( "\xE6\x03" );

   await $chip->change_config( RES => "8/12" );

   $adapter->check_and_clear( '$chip->change_config RES' );
}

done_testing;
