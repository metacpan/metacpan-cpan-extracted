#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Image::PNG::Libpng 'read_from_scalar';
use LWP::Simple;
my $image_data = get 'http://libpng.org/pub/png/img_png/libpng-88x31.png';
# Now $image_data contains the PNG file
my $png = read_from_scalar ($image_data);
# Now $png contains the PNG information from the image.
# Get the header.
my $header = $png->get_IHDR ();
printf "Your PNG has width %d and height %d\n", $header->{width}, $header->{height};

