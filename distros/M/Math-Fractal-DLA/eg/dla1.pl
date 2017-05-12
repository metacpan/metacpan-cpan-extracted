#!/usr/bin/perl -w

use strict;
use Math::Fractal::DLA;

my $width = 500;
my $height = 500;
my $type = "Explode";
my $debug = 1;

my $fractal = new Math::Fractal::DLA;
if ($debug) { $fractal->debug(debug => 1, logfile => "dla.log"); }
$fractal->setType($type);

$fractal->setSize(width => $width, height => $height);
$fractal->setBackground(r => 245, g => 245, b => 180);
$fractal->setColors(5);
$fractal->setBaseColor(base_r => 10, base_g => 100, base_b => 100, add_r => 50, add_g => 0, add_b => 0);
if ($type eq "Explode")
{ $fractal->setStartPosition(x => 250, y => 250); }
$fractal->setPoints(50000);
$fractal->setFile("dla.png");
$fractal->generate(); 
$fractal->writeFile();
undef $fractal;


