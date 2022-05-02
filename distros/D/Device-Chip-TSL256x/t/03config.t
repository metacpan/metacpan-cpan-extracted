#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::TSL256x;

my $chip = Device::Chip::TSL256x->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_config
{
   $adapter->expect_write_then_read( "\x80", 1 )
      ->returns( "\x00" );
   $adapter->expect_write_then_read( "\x81", 1 )
      ->returns( "\x02" );

   is_deeply( await $chip->read_config,
      {
         POWER => "OFF",
         GAIN  => 1,
         INTEG => "402ms",
         integ_msec => 402,
      },
      '$chip->read_config returns config'
   );

   # subsequent read does not talk to chip a second time
   await $chip->read_config;

   $adapter->check_and_clear( '$chip->read_config' );

   # gut-wrench to clear test data
   use Object::Pad ':experimental(mop)';
   undef Object::Pad::MOP::Class->for_class( ref $chip )->get_field( '$_TIMINGbyte' )->value( $chip );
}

# ->change_config
{
   $adapter->expect_write_then_read( "\x81", 1 )
      ->returns( "\x02" );
   $adapter->expect_write( "\x81\x12" );

   await $chip->change_config( GAIN => 16 );

   # subsequent read does not talk to chip a second time but yields new values
   is_deeply( await $chip->read_config,
      {
         POWER => "OFF",
         GAIN  => 16,
         INTEG => "402ms",
         integ_msec => 402,
      },
      '$chip->read_config returns new config after ->change_config'
   );

   $adapter->check_and_clear( '$chip->change_config' );
}

done_testing;

