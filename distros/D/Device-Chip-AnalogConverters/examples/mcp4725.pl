#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::MCP4725;
use Device::Chip::Adapter;

use Getopt::Long;

GetOptions(
   'eeprom=i'       => \my $EEPROM,
   'p|print-config' => \my $PRINT_CONFIG,

   'adapter|A=s' => \( my $ADAPTER ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $chip = Device::Chip::MCP4725->new;
await $chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
);

await $chip->protocol->power(1);

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
   $chip and $chip->protocol->power(0)->get;
}

if( defined $EEPROM ) {
   await $chip->write_dac_and_eeprom( $EEPROM );
}

if( $PRINT_CONFIG ) {
   my $config = await $chip->read_config;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

foreach my $code ( 0 .. 4095 ) {
   await $chip->write_dac( $code );
}
