#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::MPL3115A2;

my $chip = Device::Chip::MPL3115A2->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_config
{
   $adapter->expect_write_then_read( "\x26", 3 )
      ->returns( "\x00\x00\x00" );

   is_deeply( await $chip->read_config,
      {
         SBYB        => "STANDBY",
         OST         => '',
         RST         => '',
         OS          => 1,
         RAW         => '',
         ALT         => '',
         ST          => 1,
         ALARM_SEL   => '',
         LOAD_OUTPUT => '',
         IPOL1       => '',
         PP_OD1      => '',
         IPOL2       => '',
         PP_OD2      => '',
      },
      '$chip->read_config'
   );

   $adapter->check_and_clear( '$chip->read_config' );
}

# ->change_config
{
   # TODO bug - this shouldn't re-write unchanged bytes
   $adapter->expect_write( "\x26" . "\x80\x00\x00" );

   await $chip->change_config( ALT => 1 );

   $adapter->check_and_clear( '$chip->change_config' );
}

done_testing;
