#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::ADS1115;
use Device::Chip::Adapter;

use Getopt::Long;
use Time::HiRes qw( sleep );

GetOptions(
   'p|print-config' => \my $PRINT_CONFIG,

   'adapter|A=s' => \( my $ADAPTER ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $chip = Device::Chip::ADS1115->new;
$chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
)->get;

$chip->protocol->power(1)->get;

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
   $chip and $chip->protocol->power(0)->get;
}

$chip->change_config(
   PGA => "4.096V",
   DR  => "32",
)->get;

if( $PRINT_CONFIG ) {
   my $config = $chip->read_config->get;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

sleep 1;

foreach my $ch ( 0, 1 ) {
   $chip->change_config(
      MUX => $ch,
   )->get;

   $chip->trigger->get;
   sleep 0.2;

   printf "Channel %d: %.3f\n", $ch, $chip->read_adc_voltage->get;
}
