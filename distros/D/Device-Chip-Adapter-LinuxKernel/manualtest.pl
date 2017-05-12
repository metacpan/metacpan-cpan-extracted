#!/usr/bin/env perl

use strict;
use warnings;

use lib './lib';
use Data::Dumper;

use Device::Chip::Adapter::LinuxKernel;
#$Device::Chip::Adapter::LinuxKernel::__TESTDIR="testdirs";

my $kernelchip = Device::Chip::Adapter->new_from_description("LinuxKernel");

my $gpio = $kernelchip->make_protocol("I2C");

$gpio->configure(bus => '/dev/i2c-1', addr => 0x08);

$gpio->write("\0Hello World");
