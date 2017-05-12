#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Image-Base-PNGwriter.
#
# Image-Base-PNGwriter is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Image-Base-PNGwriter is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-PNGwriter.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use Image::Base::PNGwriter;

my $image = Image::Base::PNGwriter->new (-width  => 200,
                                         -height => 100);

$image->line (10,10, 40,40, '#2020FF');
$image->line (10,90, 40,60, '#FFA000');

$image->rectangle (50,10, 90,40, '#FFFFFF');
$image->rectangle (50,90, 90,60, '#00F5F5', 1);

$image->ellipse (100,10, 140,40, '#FF0000');
$image->ellipse (100,60, 140,90, '#F5F500', 1);

$image->diamond (150,10, 190,40, '#00FF00');
$image->diamond (150,60, 190,90, '#F500F5', 1);

my $filename = "$ENV{HOME}/tux/web/image-base-pngwriter/sample.png";
$image->save($filename);
system 'xzgv', '-g', '250x140', $filename;
exit 0;
