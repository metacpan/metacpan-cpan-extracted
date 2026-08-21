#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::SHT4x;

my $chip = Device::Chip::SHT4x->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_config
{
   # SHT4x's config is purely virtual within the module. No IO is expected

   is( await $chip->read_config,
      {
         precision       => "high",
         heater_power    => "off",
         heater_duration => "off",
         heater_interval => undef,
         heater_cooldown => 5,
         heater_max_temperature => 65,
         heater_min_humidity    => 80,
      },
      '->read_config returns config'
   );

   $adapter->check_and_clear( '->read_config' );
}

# ->change_config
{
   await $chip->change_config( precision => "medium" );

   is( await $chip->read_config,
      {
         precision       => "medium",
         heater_power    => "off",
         heater_duration => "off",
         heater_interval => undef,
         heater_cooldown => 5,
         heater_max_temperature => 65,
         heater_min_humidity    => 80,
      },
      '->read_config returns updated precision config'
   );

   $adapter->check_and_clear( '->read_config after ->change_config precision' );
}

# heater config overrides precision
{
   await $chip->change_config(
      heater_power    => "110mW",
      heater_duration => "0.1s",
      heater_interval => 5,
   );

   is( await $chip->read_config,
      {
         precision       => "high", # heater overrides this
         heater_power    => "110mW",
         heater_duration => "0.1s",
         heater_interval => 5,
         heater_cooldown => 5,
         heater_max_temperature => 65,
         heater_min_humidity    => 80,
      },
      '->read_config returns updated heater config'
   );

   $adapter->check_and_clear( '->read_config after ->change_config heater' );
}

done_testing;
