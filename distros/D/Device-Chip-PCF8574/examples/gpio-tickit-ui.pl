#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::Ex::GPIOTickitUI;

use Device::Chip::Adapter;

use Future::AsyncAwait;

use Getopt::Long;

GetOptions(
   'adapter|A=s' => \my $ADAPTER,
   'chip|C=s'    => \( my $CHIP = "PCF8574" ),
   'mount|M=s'   => \my $MOUNTPARAMS,
) or exit 1;

require "Device/Chip/$CHIP.pm";
my $chip = ${\"Device::Chip::$CHIP"}->new;

await $chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ), $MOUNTPARAMS,
);

await $chip->protocol->power(1);

END { $chip->protocol->power(0)->get; }
$SIG{INT} = $SIG{TERM} = sub { exit 1 };

Device::Chip::Ex::GPIOTickitUI->run(
   $chip->as_adapter
);
