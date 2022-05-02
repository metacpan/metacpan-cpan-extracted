#!/usr/bin/perl

use v5.26;
use warnings;

use Future::AsyncAwait;

use Device::Chip::INA219;
use Device::Chip::Adapter;
use Getopt::Long;

GetOptions(
   'adapter|A=s' => \my $ADAPTER,
   'mount|M=s'   => \my $MOUNTPARAMS,
) or exit 1;

my $ina = Device::Chip::INA219->new;

await $ina->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
);

await $ina->change_config(
   BADC => 4,
   SADC => 4,
   PG   => "80mV",
);

while(1) {
   my $vbus = $ina->read_bus_voltage->get / 1000;
   printf "Bus voltage: %.3fV\n", $vbus;

   my $vshunt = $ina->read_shunt_voltage->get;
   # Module has a 0.1ohm shunt resistor
   my $ishunt = $vshunt / 0.1;

   printf "Shunt current: %3.1fmA\n", $ishunt / 1000;

   sleep 1;
}
