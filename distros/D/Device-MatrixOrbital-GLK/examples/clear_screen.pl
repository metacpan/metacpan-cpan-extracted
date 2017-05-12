#!/usr/bin/perl
#
# Very simple example which just clears the screen
#

use strict;
use warnings;
use Device::MatrixOrbital::GLK;

my $lcd = new Device::MatrixOrbital::GLK();
$lcd->clear_screen();
