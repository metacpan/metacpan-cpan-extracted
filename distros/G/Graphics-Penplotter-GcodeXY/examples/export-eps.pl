#!/usr/bin/perl

# import an SVG, and place, rotate and scale it.
# the original SVG (car.svg) produced errors, so it was run through vpype using the following command:
# vpype read car.svg linesort write --format svg car-vp.svg
# then export as postscript file

use strict;
use warnings;
use Graphics::Penplotter::GcodeXY;

# create a gcode object
my $g = new Graphics::Penplotter::GcodeXY(
              papersize => "A3",
              units     => "pt",
            );

   # specify place, orientation, and size
   $g->translate(250,250);
   $g->rotate(90);
   $g->scale(6.0);
   # import it
   $g->importsvg('car-vp.svg');
   # generate gcode
   $g->exporteps('car-vp.ps');

1;
