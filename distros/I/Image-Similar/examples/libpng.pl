#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Image::PNG::Libpng ':all';
my $img = read_png_file ('my.png');
my $is = load_image ($img);

