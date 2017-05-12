#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::TSL256x;

my $chip = Device::Chip::TSL256x->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_config
{
   $adapter->expect_write_then_read( "\x81", 1 )
      ->returns( "\x02" );

   is_deeply( $chip->read_config->get,
      {
         GAIN => 1,
         INTEG => "402ms",
      },
      '$chip->read_config returns config'
   );

   # subsequent read does not talk to chip a second time
   $chip->read_config->get;

   $adapter->check_and_clear( '$chip->read_config' );

   # gut-wrench to clear test data
   undef $chip->{TIMINGbytes};
}

# ->change_config
{
   $adapter->expect_write_then_read( "\x81", 1 )
      ->returns( "\x02" );
   $adapter->expect_write( "\x81\x12" );

   $chip->change_config( GAIN => 16 )->get;

   # subsequent read does not talk to chip a second time but yields new values
   is_deeply( $chip->read_config->get,
      {
         GAIN  => 16,
         INTEG => "402ms",
      },
      '$chip->read_config returns new config after ->change_config'
   );

   $adapter->check_and_clear( '$chip->change_config' );
}

done_testing;

