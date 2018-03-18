#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::Ex::TickitUI;

use Device::Chip::Adapter;
use Getopt::Long;

GetOptions(
   'adapter|A=s' => \( my $ADAPTER ),
   'mode|M=s'    => \( my $STARTMODE = "GPIO" ),
) or exit 1;

Device::Chip::Ex::TickitUI->run(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   startmode => $STARTMODE,
);
