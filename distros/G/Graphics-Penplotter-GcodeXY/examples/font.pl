#!/usr/bin/perl

# font example using Arial
# both outline and hatching examples

use strict;
use warnings;
use Graphics::Penplotter::GcodeXY;
use Font::FreeType;

my $font   = 'arial.ttf';
my $string = 'She Sells Seashells by the Seashore';

# create a gcode object
my $g = new Graphics::Penplotter::GcodeXY(
   papersize => "A3",
   units     => "pt",
   id        => "font-example",
   );

   # add your private list of font directories here, if necessary,
   # or modify the current entries
   $g->addfontpath("~/Documents/fonts/lexia/",
                   "~/Documents/fonts/main/",
                   "~/Documents/fonts/other/"
                  );
                  
   # create a font face, arial size 40
my $f_a_40 = $g->setfont($font, 40);

   # save the graphics state - the current point will be at the end of the string after plotting.
   # This matters when plotting more stuff afterwards.
   $g->gsave();
   
   ####### first the hatched version

   # location of first character
   $g->translate(100,200);

   # plot the string and hatch it
   $g->stroketextfill($f_a_40, $string);
   
   # restore the original graphics state
   $g->grestore();
   
   ####### now the unhatched (outline only) version

   # location of first character
   $g->translate(100,400);

   # plot the string, no hatching
   $g->stroketext($f_a_40, $string);
   
   # the result
   $g->output('font.gcode');


