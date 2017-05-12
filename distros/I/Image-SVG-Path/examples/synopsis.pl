#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Image::SVG::Path 'extract_path_info';
my $path_d_attribute = "M9.6,20.25c0.61,0.37,3.91,0.45,4.52,0.34c2.86-0.5,14.5-2.09,21.37-2.64c0.94-0.07,2.67-0.26,3.45,0.04";
my @path_info = extract_path_info ($path_d_attribute);
