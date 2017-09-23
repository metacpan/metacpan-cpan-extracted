#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::AD5691R;
use Device::Chip::Adapter;

use Getopt::Long;

GetOptions(
   'p|print-config' => \my $PRINT_CONFIG,

   'adapter|A=s' => \( my $ADAPTER = "FTDI" ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $chip = Device::Chip::AD5691R->new;
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
   GAIN => 2,
)->get;

foreach my $code ( 0 .. 4095 ) {
   $chip->write_dac( $code )->get;
}
