#!/usr/bin/perl

# template for GcodeXY project

use strict;
use warnings;
use Graphics::Penplotter::GcodeXY;

# create a gcode object
# shows all keys with its defaults
my $g = new Graphics::Penplotter::GcodeXY(
        header     => "G20\nG90\nG17\nF 20\nG92 X 0 Y 0 Z 0\nG00 Z 0\n",  # must end with penupcmd
        trailer    => "G00 Z 0\nG00 X 0 Y 0\n",                           # return to origin
        penupcmd   => "G00 Z 0\n",   # usually plotter independent
        pendowncmd => "G00 Z 0.2\n", # plotter dependent
        papersize  => undef,         # paper size e.g. "A3"
        xsize      => undef,         # bounding box x
        ysize      => undef,         # bounding box y
        units      => 'in',          # inches is used internally
        feedrate   => 20,            # write speed
        margin     => 1.0,           # margin as a PERCENTAGE
        outfile    => '',            # gcode output file name
        curvepts   => 50,            # line segments per curve
        check      => 0,             # print stats and advice
        warn       => 0,             # out of page bounds warning
        hatchsep   => 0.012,         # inches, equivalent to 0.3 mm (the tip of a BIC ballpoint pen)
        id         => '',            # useful for debugging, esp. when using multiple objects
        optimize   => 1,             # peephole optimizer is on by default
        );

# your code goes here
        
        
$g->output("file.gcode");
   
