#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use Cairo;
use Image::CairoSVG;
my $cairosvg = Image::CairoSVG->new ();
my $surface = $cairosvg->render ("$Bin/locust.svg");
$surface->write_to_png ("$Bin/locust.png");
