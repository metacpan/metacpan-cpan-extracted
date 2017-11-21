#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::MAX11200;
use Device::Chip::Adapter;

use Getopt::Long;
use Time::HiRes qw( sleep );

GetOptions(
   'p|print-config' => \my $PRINT_CONFIG,
   'c|calibrate'    => \my $SELFCAL,

   'adapter|A=s' => \( my $ADAPTER = "FTDI" ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $chip = Device::Chip::MAX11200->new;
$chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
)->get;

$chip->protocol->power(1)->get;
END { $chip->protocol->power(0)->get if $chip }

$SIG{INT} = $SIG{TERM} = sub { exit 0 };

if( $SELFCAL ) {
   $chip->change_config(
      NOSCG => 0,
      NOSCO => 0,
   )->get;

   $chip->selfcal->get;
   sleep 0.2; # selfcal takes 200msec

   printf "SCOC=%06x, SCGC=%06x\n",
      $chip->read_selfcal_offset->get, $chip->read_selfcal_gain->get;
}

if( $PRINT_CONFIG ) {
   my $config = $chip->read_config->get;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

while(1) {
   $chip->trigger->get;
   sleep 0.2;

   my $reading = $chip->read_adc->get;
   printf STDERR "Reading raw=%06X/%d; scale %.6f\n",
      $reading, $reading, $reading / (1<<24);
}
