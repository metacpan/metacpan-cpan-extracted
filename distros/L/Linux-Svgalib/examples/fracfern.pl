#!/usr/bin/perl -w

use strict;

use Linux::Svgalib;

use constant NX => 640;
use constant NY => 480;

sub MIN
{
 my ($x, $y) = @_;
 return ($x < $y ? $x : $y);
}


my @a = (0.0,0.2,-0.15,0.75);
my @b = (0.0,-0.26,0.28,0.04);
my @c = (0.0,0.23,0.26,-0.04);
my @d = (0.16,0.22,0.24,0.85);
my @e = (0.0,0.0,0.0,0.0);
my @f = (0.0,1.6,0.44,1.6);

   my ( $i,$j,$k);
   my $n;
   my ( $ix,$iy);
   my ($r,$x,$y);
   my ($xlast,$ylast) = (1,1);
   my $xmin = 1e32;
   my $xmax = -1e32;
   my $ymin = 1e32;
   my $ymax = -1e32;
   my ($scale,$xmid,$ymid);

   if (@ARGV < 1) {
      die "Usage: $0 nsteps\n";
   }
   $n = shift;

   my $screen = Linux::Svgalib->new();

   $screen->init();
   $screen->setmode(4);
   $screen->setcolor(15);

   for ($j=0; $j < 2 ; $j++) {
      for ($i=0; $i < $n; $i++) {
         $r = int rand(100) ;
         if ($r < 10)
         {
            $k = 0;
         }
         elsif ($r < 18)
         {
            $k = 1;
         }
         elsif ($r < 26)
         {
            $k = 2;
         }
         else
         {
            $k = 3;
         }
         $x = $a[$k] * $xlast + $b[$k] * $ylast + $e[$k];
         $y = $c[$k] * $xlast + $d[$k] * $ylast + $f[$k];
         $xlast = $x;
         $ylast = $y;
         if ($x < $xmin)
         { 
           $xmin = $x;
         }
         if ($y < $ymin) { $ymin = $y };
         if ($x > $xmax) { $xmax = $x };
         if ($y > $ymax) { $ymax = $y };
         if ($j == 1) 
         {
            $scale = MIN(NX / ($xmax - $xmin),NY / ($ymax - $ymin));
            $xmid = ($xmin + $xmax) / 2;
            $ymid = ($ymin + $ymax) / 2;
            $ix = NX / 2 + ($x - $xmid) * $scale;
            $iy = NY / 2 + ($y - $ymid) * $scale;
            $screen->drawpixel($ix, $iy);
         }
      }
   }

   $screen->getch();
   $screen->setmode(TEXT);

