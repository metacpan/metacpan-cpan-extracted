#!/usr/bin/env perl

use strict;
use warnings;

use lib './lib';

use Device::Chip::PCA9685;
use Device::Chip::Adapter;

use Getopt::Long;

GetOptions(
    # This is the i2c bus on an RPI 2 B+
    'adapter|A=s' => \(my $ADAPTER = "LinuxKernel:bus=/dev/i2c-1"),
) or exit 1;

my $adapter = Device::Chip::Adapter->new_from_description($ADAPTER);

my $chip = Device::Chip::PCA9685->new();
$chip->mount($adapter)->get;

$chip->enable()->get;
$chip->set_frequency(400)->get; # 400 Hz

for (0..4095) {
    $chip->set_channel_value(0, $_)->get;
}
