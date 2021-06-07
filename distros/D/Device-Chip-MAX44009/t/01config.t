#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::MAX44009;

my $chip = Device::Chip::MAX44009->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_config
{
   $adapter->expect_write_then_read( "\x02", 1 )
      ->returns( "\x03" );

   is_deeply( await $chip->read_config,
      {
         CONT   => '',
         MANUAL => '',
         CDR    => '',
         TIM    => 100,
      },
      '->read_config returns config'
   );

   # subsequent read does not talk to chip a second time
   await $chip->read_config;

   $adapter->check_and_clear( '->read_config' );
}

# ->change_config
{
   $adapter->expect_write( "\x02\x01" );

   await $chip->change_config(
      TIM => 400,
   );

   # subsequent read does not talk to chip a second time but yields new values
   is_deeply( await $chip->read_config,
      {
         CONT   => '',
         MANUAL => '',
         CDR    => '',
         TIM    => 400,
      },
      '$chip->read_config returns new config after ->change_config'
   );

   $adapter->check_and_clear( '$chip->change_config' );
}

done_testing;
