#!/usr/bin/perl

use 5.026;
use utf8;
use strict;
use warnings;

use Device::Yeelight;

my $yeelight = Device::Yeelight->new;
foreach my $device ( @{ $yeelight->search } ) {
    $device->start_cf( 3, 1,
        "50,2,1700,1," . "360000,2,1700,10," . "540000,2,2700,100",
    ) if $ARGV[0] eq 'sunrise';
    $device->start_cf( 3, 2,
        "50,2,2700,10," . "180000,2,1700,5," . "420000,1,16731136,1",
    ) if $ARGV[0] eq 'sunset';
    $device->start_cf( 0, 1, "4000,1,5838189,1" . "4000,1,6689834,1", )
      if $ARGV[0] eq 'romance';
}
