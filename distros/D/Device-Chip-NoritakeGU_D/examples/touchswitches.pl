#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::NoritakeGU_D;
use Device::Chip::Adapter;

use Future::AsyncAwait;
use Getopt::Long qw( :config no_ignore_case );
use Time::HiRes qw( sleep );

GetOptions(
   'i|interface=s' => \(my $INTERFACE = "I2C"),
   'adapter|A=s' => \( my $ADAPTER ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $chip = Device::Chip::NoritakeGU_D->new( interface => $INTERFACE );

await $chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
);

await $chip->power(1);

await $chip->initialise;

while(1) {
   sleep 0.1;

   my $switches = await $chip->read_touchswitches;
   $switches->{$_} and print "KEY $_\n" for sort keys %$switches;
}
