#!/usr/bin/perl

use strict;
use warnings;
use Graphics::Penplotter::GcodeXY;
use Test::Simple 'no_plan';
use File::Spec;

# create a gcode object
my $g = new Graphics::Penplotter::GcodeXY(
   papersize => "A3",
   units     => "pt",
   );
my $svg_path = File::Spec->catfile('t', 'data', 'car-vp.svg');

ok($g->importsvg($svg_path));
   
