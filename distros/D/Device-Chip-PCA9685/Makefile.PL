#!/usr/bin/env perl

use inc::Module::Install;

name 'Device-Chip-PCA9685';
all_from 'lib/Device/Chip/PCA9685.pm';

requires 'Device::Chip' => 0;

WriteAll;
