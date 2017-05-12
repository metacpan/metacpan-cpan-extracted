#!/usr/bin/perl

# This is an example script demonstrating Image::RGBA interpolation.
# Use it to scale an image by any factor.

use strict;
use warnings;
use Image::Magick;
use lib 'lib';
use Image::RGBA;

if ($#ARGV ne 3)
{
    die "Incorrect number of arguments\n" .
    "Usage $0 <scale> (simple|linear|spline16) <infile> <outfile>\n" .
    "e.g.  $0 1.618 spline16 input.jpg output.png\n";
}

my ($scale, $sample, $in_file, $out_file) = @ARGV;

# sort-out the input image

my $input = new Image::Magick;
   $input->Read ($in_file);

my $rgba = new Image::RGBA (image => $input, sample => $sample);

# the output image needs a size

my $width  = int ($scale * $input->Get ('width'));
my $height = int ($scale * $input->Get ('height'));

my $output = new Image::Magick (size => "$width" ."x". "$height");
   $output->Read ("NULL:black");
   $output->Transparent (color => 'black');

my $rgba_out = new Image::RGBA (image => $output);

# iterate through all the rows of the _output_ image

for my $v (0 .. $height - 1)
{
    for my $u (0 .. $width - 1)
    {
       $rgba_out->Pixel ($u, $v, $rgba->Pixel ($u/$scale, $v/$scale));
    }
    print STDERR "#";
}
print STDERR "\n";

$rgba_out->Image->Write ($out_file);

1;

