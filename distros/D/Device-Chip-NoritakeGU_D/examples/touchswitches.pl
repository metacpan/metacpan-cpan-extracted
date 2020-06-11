#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::NoritakeGU_D;
use Device::Chip::Adapter;
use Getopt::Long qw( :config no_ignore_case );
use Time::HiRes qw( sleep );

GetOptions(
   'i|interface=s' => \(my $INTERFACE = "I2C"),
   'adapter|A=s' => \( my $ADAPTER ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $chip = Device::Chip::NoritakeGU_D->new( interface => $INTERFACE );

$chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
)->get;

$chip->power(1)->get;

$chip->initialise->get;

while(1) {
   sleep 0.1;

   my $switches = $chip->read_touchswitches->get;
   $switches->{$_} and print "KEY $_\n" for sort keys %$switches;
}
