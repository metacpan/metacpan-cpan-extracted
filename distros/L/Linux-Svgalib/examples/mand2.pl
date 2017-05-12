#!/usr/bin/perl -w

use strict;
use Linux::Svgalib;

use vars qw($P @Q $col $row @colours );

my (
    $max_iterations,
    $max_size )       = (512,4);

my $screen = Linux::Svgalib->new();

$screen->init();
$screen->setmode(8);

my ($XMax,$XMin,$YMax,$YMin) = (1.2,-2.0,1.2,-1.2);

my $maxcol = $screen->getxdim();
my $maxrow = $screen->getydim();
my $max_colours = $screen->getcolors();

my $deltaP = ($XMax - $XMin) / $maxcol;
my $deltaQ = ($YMax - $YMin) / $maxrow;

$Q[0] = $YMax;


$screen->clear();

for( 1 .. $maxrow )
{
    $Q[$_] = $Q[$_ -1] - $deltaQ;
}

$P = $XMin;

for $col ( 0 .. $maxcol -1 )
{
    for $row ( 0 .. $maxrow - 1)
    {
        my ($X,$Y,$XSquare,$YSquare) = (0,0,0,0);

        my $colour = 1;

        while (( $colour < $max_iterations ) &&
               (($XSquare + $YSquare ) < $max_size ))
        {
             $XSquare = $X * $X;
             $YSquare = $Y * $Y;

             $Y *= $X;
             $Y += $Y + $Q[$row];
             $X = $XSquare - $YSquare + $P;
             $colour++;
        }
           $screen->setcolor($colour % $max_colours);
           $screen->drawpixel($col,$row);
    }
    $P += $deltaP;
}

$screen->getch();

$screen->setmode(TEXT);
