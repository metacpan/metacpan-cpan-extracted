#!/usr/bin/perl

# line testing

use strict;
use warnings;
use Graphics::Penplotter::GcodeXY;


# create a gcode object
my $p = new Graphics::Penplotter::GcodeXY(
          papersize => "A3",
          units     => "pt",
          check     => 1,
          warn      => 1,
          optimize  => 1,
          id        => "triangles",
          outfile   => "01-triangles.gcode"
        );

my $rounds = 50;   # number of lines per side
my $perc   = 0.05;
my $sqrt3  = sqrt(3);
my $cx = 400;
my $cy = 600;
my $width = 300;
my $tl1x = $cx - $width;
my $tl1y = $cy;
my $tl2x = $cx - $width/2;
my $tl2y = $cy + $width*$sqrt3/2;
my $tm1x = $tl2x;
my $tm1y = $tl2y;
my $tm2x = $cx + $width/2;
my $tm2y = $cy + $width*$sqrt3/2;
my $tr1x = $tm2x;
my $tr1y = $tm2y;
my $tr2x = $cx + $width;
my $tr2y = $cy;
my $br1x = $tr2x;
my $br1y = $tr2y;
my $br2x = $tr1x;
my $br2y = $cy - $width*$sqrt3/2;
my $bm1x = $br2x;
my $bm1y = $br2y;
my $bm2x = $tl2x;
my $bm2y = $cy - $width*$sqrt3/2;
my $bl1x = $bm2x;
my $bl1y = $bm2y;
my $bl2x = $tl1x;
my $bl2y = $tl1y;


dotriangle($tl1x, $tl1y, $tl2x, $tl2y, $cx, $cy);
dotriangle($tm2x, $tm2y, $tm1x, $tm1y, $cx, $cy);
dotriangle($tr1x, $tr1y, $tr2x, $tr2y, $cx, $cy);
dotriangle($br2x, $br2y, $br1x, $br1y, $cx, $cy);
dotriangle($bm1x, $bm1y, $bm2x, $bm2y, $cx, $cy);
dotriangle($bl2x, $bl2y, $bl1x, $bl1y, $cx, $cy);

$p->output();
exit;

############## end main #############################

sub dotriangle {
my ($x1, $y1, $x2, $y2, $x3, $y3);
my ($x1old,$y1old, $x2old, $y2old, $x3old, $y3old) = @_;

      $p->line($x1old,$y1old, $x2old, $y2old);
      $p->line($x2old,$y2old, $x3old, $y3old);
      $p->line($x3old,$y3old, $x1old, $y1old);
      
      foreach my $i (1 .. $rounds) {
            $x1 = $x1old + ($x2old-$x1old)*$perc;
            $x2 = $x2old + ($x3old-$x2old)*$perc;
            $x3 = $x3old + ($x1old-$x3old)*$perc;
            $y1 = $y1old + ($y2old-$y1old)*$perc;
            $y2 = $y2old + ($y3old-$y2old)*$perc;
            $y3 = $y3old + ($y1old-$y3old)*$perc;
            $x1old = $x1;
            $x2old = $x2;
            $x3old = $x3;
            $y1old = $y1;
            $y2old = $y2;
            $y3old = $y3;
            # plotter optimization: draw the lines alternately
            # in opposite directions - TODO
            $p->line($x1old,$y1old, $x2old, $y2old);
            $p->line($x2old,$y2old, $x3old, $y3old);
            $p->line($x3old,$y3old, $x1old, $y1old);
      }
}
