#!/usr/bin/perl -w

use strict;

use Linux::Svgalib ':all';



my(  $ra,
     $in,
     $in2,
     $x,
     $y,
     $c1,
     $c2,
     $k,
     $nx,
     $ny,
     $key);

  my ( $an, $an2) = (0,0);

  my $vga = Linux::Svgalib->new();

  $vga->init();
  $vga->setmode(4);

  $c1 = 640.0/3.1; 
  $c2 = 480.0/2.1;

  do
  {
    $vga->clear();

    $in = 6.24 * qsrandom(); 
    $in2 = 6.24 * qsrandom();

    while (($key = $vga->getkey()) == 0)
    {
      $an  += $in; 
      $an2 += $in2;
      $ra = sin($an2);
      $x = $ra * sin($an); 
      $y = $ra * cos($an);
      $nx = $c1 * ($x + 1.55); 
      $ny = $c2 * ($y + 1.05);
      $k = $vga->getpixel($nx,$ny);
      $vga->setcolor(++$k);
      $vga->drawpixel($nx,$ny) if ( $k <256 );
    } 

  } while (($key == 78) || ($key == 110));

  $vga->setmode(TEXT);

sub qsrandom
{
   my($random_integer,
      $temp_integer,
      $random_double,
      $temp_double);

   $random_double = rand();
   $temp_double = rand();
   $random_double += $temp_double;
   return($random_double);
}

