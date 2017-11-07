#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Image::SVG::Path 'extract_path_info';
use Data::Dumper;
my $path_d_attribute = "M9.6,20.25c0.61,0.37,3.91,0.45,4.52,0.34";
my @path_info = extract_path_info ($path_d_attribute);
print Dumper (\@path_info);
