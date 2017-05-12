#!/usr/bin/perl

# A spherical image slicer for patterning spheres
# Copyright 2001 Bruno Postle <bruno@postle.net>
#
# 2002-05-05 lots of cleaning-up and bug-fixes.  Now uses quality
#            interpolators for sampling.
# 
# 2002-09-10 switched to use the new Image::RGBA module for sampling
#  
# 2002-12-27 Now uses new Image::RGBA api
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.

use strict;
use warnings;

use Image::Magick;             # image stuff
use Math::Trig;                # math stuff
use Math::Trig ':radial';      # more math stuff
use lib 'lib';                 # help, where are we?
use Image::RGBA;               # quality image sampling

if ($#ARGV ne 2)
{
    die "Incorrect number of arguments\n" .
    "Usage $0 <number of panels> <circumference> <filename>\n" .
    "e.g.  $0 16 1600 input.jpg\n";
}

my ($segments, $circumference, $in_file) = @ARGV;

# this can be changed to tif, gif, jpg or whatever..
my $out_filetype = "png";

# output height, always half the circumference
my $out_height = int ($circumference / 2);

# output radius in pixels
my $rho = $out_height / pi;

# width of individual panels/segments
my $out_width = int (($circumference / pi) * tan (pi / $segments));

# open the input image
my $in = new Image::Magick;
   $in->ReadImage ($in_file);

my $in_width = $in->Get ('width');
my $in_height = $in->Get ('height');
print STDERR "Input image is ". $in_width ."x". $in_height .".\n";

# object to sample pixels from
my $rgba = new Image::RGBA (image => $in,
                           sample => 'spline16');

# do each panel/segment
for my $panel (0 .. $segments - 1)
{
    my $out = new Image::Magick (size => $out_width ."x". $out_height);
       $out->ReadImage ('NULL:black');
       $out->Transparent (color => 'black');

    my $rgba_out = new Image::RGBA (image => $out);

    # This is the angle to rotate the world for each panel

    my $theta_offset = (pi / $segments) * ($panel + 0.5) * 2;

    # do each row in the output image

    for my $v (0 .. $out_height - 1)
    {
        # do each column in the output image

        for my $u (0 .. $out_width - 1)
        {
            # getting a 'y' coordinate is easy
            my $y = $u - ($out_width / 2);

            # phi is inclination from the nadir to zenith
            my $phi = ((($out_height - $v) / $out_height) * pi);

            # rho is the radius, now we can get 'x & z'
            my ($x, $foo, $z) = spherical_to_cartesian ($rho, 0, $phi);

            # now to calculate theta from the 'x, y & z' coordinates
            my ($bar, $theta, $baz) = cartesian_to_spherical ($x, $y, $z);

            # we only want to paint pixels in the visible segment
            if (abs ($theta) < pi / $segments)
            {
                # different panels need different parts of the world
                $theta += $theta_offset;

                # figure-out which pixel we need from the source image
                my $m = ($theta / (2 * pi)) * $in_width;
                my $n = $in_height - (($phi / pi) * $in_height);

                $rgba_out->Pixel ($u, $v, $rgba->Pixel ($m, $n));
            }
        }
    }

    print STDERR "Writing panel $panel - $out_width" ."x". "$out_height\n";

    $rgba_out->Image->Write ('panel-'. sprintf("%03d", $panel) .".$out_filetype");
}

1;
