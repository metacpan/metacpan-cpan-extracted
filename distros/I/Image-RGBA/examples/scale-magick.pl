#!/usr/bin/perl

# This is an example script that does exactly the same job as the
# scale.pl script (except by using Image::Magick functions only).  Use
# it to scale an image by any factor.

use strict;
use warnings;
use Image::Magick;

if ($#ARGV ne 2)
{
    die "Incorrect number of arguments\n" .
    "Usage $0 <scale> <infile> <outfile>\n" .
    "e.g.  $0 1.618 input.jpg output.png\n";
}

my ($scale, $in_file, $out_file) = @ARGV;

# sort-out the input image

my $input = new Image::Magick;
   $input->Read ($in_file);

# the output image needs a size

my $width  = int ($scale * $input->Get ('width'));
my $height = int ($scale * $input->Get ('height'));

my $output = new Image::Magick (size => "$width" ."x". "$height");
   $output->Read ("NULL:Black");
   $output->Transparent (color => 'black');

# iterate through all the rows of the _output_ image

for my $v (0 .. $height - 1)
{
    for my $u (0 .. $width - 1)
    {
        my $pixel = $input->Get ('pixel['. int ($u/$scale) .','. int ($v/$scale) .']');

        $output->Set ('pixel['. $u .','. $v .']' => $pixel);
    }
    print STDERR "#";
}
print "\n";

$output->Write ($out_file);

1;

