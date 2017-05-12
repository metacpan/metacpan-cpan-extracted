#!/usr/bin/perl
#

use strict;
use warnings;
use Device::MatrixOrbital::GLK;

my $lcd = new Device::MatrixOrbital::GLK();

print "LCD Type: ".$lcd->get_lcd_type()."\n";
print "LCD Version: ".$lcd->get_firmware_version()."\n";

my ($width, $height) = $lcd->get_lcd_dimensions();
print "LCD Width: $width\n";
print "LCD Height: $height\n";

