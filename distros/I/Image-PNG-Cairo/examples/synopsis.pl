#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Image::PNG::Cairo 'cairo_to_png';
use Cairo;
my $surface = Cairo::ImageSurface->new ('argb32', 100, 100);
# Draw something on surface.
my $png = cairo_to_png ($surface);
# Now can use the methods of Image::PNG::Libpng on the PNG,
# e.g. write to file.
