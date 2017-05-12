#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::Ex::GPIOTickitUI;

use Device::Chip::Adapter;

use Getopt::Long;

GetOptions(
   'adapter|A=s' => \( my $ADAPTER = "BusPirate" ),
   'chip|C=s'    => \( my $CHIP = "PCF8574" ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

require "Device/Chip/$CHIP.pm";
my $chip = ${\"Device::Chip::$CHIP"}->new;

$chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ), $MOUNTPARAMS,
)->get;

$chip->protocol->power(1)->get;

END { $chip->protocol->power(0)->get; }
$SIG{INT} = $SIG{TERM} = sub { exit 1 };

Device::Chip::Ex::GPIOTickitUI->run(
   $chip->as_adapter
);
