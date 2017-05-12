#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::HTU21D;

my $chip = Device::Chip::HTU21D->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_config
{
   $adapter->expect_write_then_read( "\xE7", 1 )
      ->returns( "\x02" );

   is_deeply( $chip->read_config->get,
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

   $chip->change_config( HEATER => 1 )->get;

   $adapter->check_and_clear( '$chip->change_config' );
}

# ->change_config new resolution
{
   $adapter->expect_write_then_read( "\xE7", 1 )
      ->returns( "\x02" );
   $adapter->expect_write( "\xE6\x03" );

   $chip->change_config( RES => "8/12" )->get;

   $adapter->check_and_clear( '$chip->change_config RES' );
}

done_testing;
