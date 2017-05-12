#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Image::SVG::Path 'reverse_path';
my $path = "M26.75,73c-2.61,6.25-5.49,12.25-8.36,17.15c-0.74,1.26-1.99,1.54-3.23,1.03";
my $reverse = reverse_path ($path);
print "$reverse\n";

