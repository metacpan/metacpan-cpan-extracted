#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use Cairo;
use Image::CairoSVG;
# Using defaults
my $dcairosvg = Image::CairoSVG->new ();
my $dsurface = $dcairosvg->render ("$Bin/urn.svg");
$dsurface->write_to_png ("$Bin/durn.png");
# Scale to 200 pixels
my $size = 200;
my $twsize = 36;
my $surface = Cairo::ImageSurface->create ('argb32', $size, $size);
my $context = Cairo::Context->create ($surface);
my $cairosvg = Image::CairoSVG->new (context => $context);
$context->scale ($size/$twsize, $size/$twsize);
$cairosvg->render ("$Bin/urn.svg");
$surface->write_to_png ("$Bin/urn.png");
