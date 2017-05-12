#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Image-Base-GD.
#
# Image-Base-GD is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-GD is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-GD.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use GD;

my $gd = GD::Image->new(1,1) || die;
my $white = $gd->colorAllocate(255,255,255);
$gd->rectangle(0,0,1,1,$white);

my $filename = 't/GIF8.png';
open my $fh, '>', $filename or die;
print $fh $gd->png(9) or die;
close $fh or die;

system <<"HERE";
pngtextadd --keyword=Author --text='Kevin Ryde' $filename;
pngtextadd --keyword=Copyright --text='Copyright 2011 Kevin Ryde

This file is part of Image-Base-GD.

Image-Base-GD is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Image-Base-GD is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with Image-Base-GD.  If not, see <http://www.gnu.org/licenses/>.
' $filename;
HERE
