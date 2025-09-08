#!/usr/bin/perl

# bunch of boxes, absolute coordinates

use strict;
use warnings;
use Graphics::Penplotter::GcodeXY;

my $eps = 0.0;

# create a gcode object
my $g = new Graphics::Penplotter::GcodeXY(
   papersize => "A3",
   units     => "in",
   id        => "boxabs",
   outfile   => '03-box-round.gcode',
   );

# draw boxes with varying round corners
foreach my $i (0, 2, 4, 6, 8) {
    foreach my $j (1, 3, 5, 7) {
        $g->boxround(0.3, $i+$eps,$j+$eps,$i+1+$eps,$j+1+$eps);
        $g->boxround(0.1, $i+1+$eps,$j+1+$eps,$i+2+$eps,$j+2+$eps);
    }
}
   

$g->output();

exit;
