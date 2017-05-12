#!/usr/bin/perl

# A demonstration of Image::photo
#
# Image::Photo, samples images using high quality interpolation.  radial
# brightness and lens barrel correction can be applied at this sampling stage.
# 
# So you can use this script for batch correction of photographs.

use strict;
use warnings;
use Image::Magick;       # image stuff
use lib 'lib';
use Image::Photo;        # quality image sampling of photos

if ($#ARGV ne 5)
{
    die "Incorrect number of arguments\n" .
    "Usage $0 <a> <b> <c> <radlum> <infile> <outfile>\n" .
    "e.g.  $0 0.0 -0.02 0.0 10.0 input.jpg output.jpg\n";
}

my ($a, $b, $c, $radlum, $in_file, $out_file) = @ARGV;

# sort out inputImage::Magick object

my $in = new Image::Magick;
   $in->ReadImage ($in_file);

# we are going to have the same size for the output image

my $width = $in->Get ('width');
my $height = $in->Get ('height');

print STDERR "Image is $width"."x"."$height.\n";

# all this just creates a blank Image::Magick canvas

my $out = new Image::Magick (size => $width ."x". $height);
   $out->ReadImage ("NULL:Black");
   $out->Transparent (color => 'black');

# create objects for reading and writing

my $inphoto = new Image::Photo (image => $in,
                               radlum => $radlum,
                                    a => $a, b => $b, c => $c);

my $outrgba = new Image::Photo (image => $out);

# do each row in the output image

for my $v (0 .. $height - 1)
{
    # do each column in the output image

    for my $u (0 .. $width - 1)
    {
        if ($u >= 0 && $u < $width && $v >= 0 && $v < $height)
        {
            $outrgba->Pixel ($u, $v, $inphoto->Pixel ($u, $v));
        }
    }
    print STDERR "#";
}
print STDERR "\n";

# Convert from the RGBA blob back to an Image::Magick object

$outrgba->Image->Write ($out_file);

1;
