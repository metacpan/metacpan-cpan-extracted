#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Image-Base-Prima.
#
# Image-Base-Prima is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Prima is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Prima.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Prima::noX11;
use Prima;

my $image = Prima::Image->create (width => 3,
                                  height => 3);
$image->begin_paint;
$image->pixel(1,1, cl::Green);
$image->end_paint;
$image->save('/tmp/foo.png') or die "Error saving:$@\n";
system "zgv -z /tmp/foo.png";
exit 0;

