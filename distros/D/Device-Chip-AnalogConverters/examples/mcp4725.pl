#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::MCP4725;
use Device::Chip::Adapter;

use Getopt::Long;

GetOptions(
   'eeprom=i'       => \my $EEPROM,
   'p|print-config' => \my $PRINT_CONFIG,

   'adapter|A=s' => \( my $ADAPTER = "FTDI" ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $chip = Device::Chip::MCP4725->new;
$chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
)->get;

$chip->protocol->power(1)->get;

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
   $chip and $chip->protocol->power(0)->get;
}

if( defined $EEPROM ) {
   $chip->write_dac_and_eeprom( $EEPROM )->get;
}

if( $PRINT_CONFIG ) {
   my $config = $chip->read_config->get;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

foreach my $code ( 0 .. 4095 ) {
   $chip->write_dac( $code )->get;
}
