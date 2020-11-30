#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::TCS3472x;

my $chip = Device::Chip::TCS3472x->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_config
{
   # TODO: This test is a bit fragile
   $adapter->expect_write_then_read( "\xA0", 2 )
      ->returns( "\x00\x00" );
   $adapter->expect_write_then_read( "\xA3", 5 )
      ->returns( "\xFF\x00\x00\x00\x00" );
   $adapter->expect_write_then_read( "\xAC", 2 )
      ->returns( "\x00\x00" );
   $adapter->expect_write_then_read( "\xAF", 1 )
      ->returns( "\x00" );

   is_deeply( $chip->read_config->get,
      {
         AEN   => '',
         AIEN  => '',
         AGAIN => 1,
         APERS => "EVERY",
         ATIME => 0,
         PON   => '',
         WEN   => '',
         WLONG => '',
         WTIME => 255,

         atime_cycles => 256,
         atime_msec   => 614.4,

         wtime_cycles => 1,
         wtime_msec   => 2.4,
      },
      '->read_config yields config'
   );

   $adapter->check_and_clear( '->read_config' );
}

# ->change_config
{
   $adapter->expect_write( "\xA0\x01" );
   $adapter->expect_write( "\xAF\x01" );

   $chip->change_config(
      PON   => 1,
      AGAIN => 4,
   )->get;

   $adapter->check_and_clear( '->change_config' );
}

done_testing;
