#!/usr/bin/env perl

use inc::Module::Install;

# Define metadata
name           'Device-Chip-Adapter-LinuxKernel';
all_from       'lib/Device/Chip/Adapter/LinuxKernel.pm';

# Specific dependencies
requires 'Carp'  => '0';
requires 'Device::SMBus'  => '0';
requires 'Device::Chip'=> '0';

WriteAll;