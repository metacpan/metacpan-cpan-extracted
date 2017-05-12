#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Image::PNG::Libpng ':all';
my $png = read_png_file ('tantei-san.png');
my $name = color_type_name ($png->get_IHDR->{color_type});
print "Your PNG has colour type $name.\n";
