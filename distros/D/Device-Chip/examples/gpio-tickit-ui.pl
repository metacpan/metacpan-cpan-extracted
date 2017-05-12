#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::Ex::GPIOTickitUI;

use Device::Chip::Adapter;
use Getopt::Long;

GetOptions(
   'adapter|A=s' => \( my $ADAPTER ),
) or exit 1;

Device::Chip::Ex::GPIOTickitUI->run(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
);
