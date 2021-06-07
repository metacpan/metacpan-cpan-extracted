#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::OPT3001;

my $chip = Device::Chip::OPT3001->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_config
{
   $adapter->expect_write_then_read( "\x01", 2 )
      ->returns( "\xC8\x10" );

   is_deeply( await $chip->read_config,
      {
         RN  => 12,
         CT  => 800,
         M   => "shutdown",
         OVF => '',
         CRF => '',
         FH  => '',
         FL  =>'',
         L   => 1,
         POL => "active-low",
         ME  => '',
         FC  => 1,
      },
      '->read_config returns config'
   );

   # subsequent read does not talk to chip a second time
   await $chip->read_config;

   $adapter->check_and_clear( '->read_config' );
}

# ->change_config
{
   $adapter->expect_write( "\x01\xCA\x10" );

   await $chip->change_config(
      M => "single"
   );

   # subsequent read does not talk to chip a second time but yields new values
   is_deeply( await $chip->read_config,
      {
         RN  => 12,
         CT  => 800,
         M   => "single",
         OVF => '',
         CRF => '',
         FH  => '',
         FL  =>'',
         L   => 1,
         POL => "active-low",
         ME  => '',
         FC  => 1,
      },
      '$chip->read_config returns new config after ->change_config'
   );

   $adapter->check_and_clear( '$chip->change_config' );
}

done_testing;
