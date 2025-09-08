#!/usr/bin/perl

# tree of pythagoras with 45 degree angles, plotted in landscape

use strict;
use warnings;
use Graphics::Penplotter::GcodeXY;

# create a gcode object
my $g = new Graphics::Penplotter::GcodeXY(
           papersize => "A3",
           units     => "pt",
           id        => "pythagoras",
           check     => 1,
           warn      => 1,
        );

my $s      = 180;     # initial size
my $hsqrt2 = 0.7071;  # half the square root of 2

# simulate landscape mode in A3
$g->translate(50,650);   # middle of page, bottom
$g->rotate(-90);

# generate the tree, 10 levels
# plotting length doubles with each additional level
pythagorastree(10);

# produce output file
$g->output('pythagoras.gcode');

# recursive pythagoras tree build, parameter is number of levels
sub pythagorastree {
my $level = shift;
    $g->box(0, 0, $s, $s);         # draw the 'trunk'
    if ($level > 0) {
       $g->gsave();
       $g->translate(0, $s);
       $g->scale($hsqrt2, $hsqrt2);
       $g->rotate(45);
       pythagorastree($level-1);   # tree on left
       $g->grestore();
       $g->translate(0.5*$s, 1.5*$s);
       $g->scale($hsqrt2, $hsqrt2);
       $g->rotate(-45);
       pythagorastree($level-1);   # tree on right
    }
}
