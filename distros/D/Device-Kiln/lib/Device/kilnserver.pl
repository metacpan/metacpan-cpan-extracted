#!/usr/bin/perl

use Device::Kiln;

my $meter = Device::Kiln->new({
				serialport => "/dev/ttyS0",
				interval => 5 
		});

$meter->run();
