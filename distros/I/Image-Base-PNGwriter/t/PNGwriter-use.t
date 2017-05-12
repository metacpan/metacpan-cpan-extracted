#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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

## no critic (RequireUseStrict, RequireUseWarnings)
use Image::Base::PNGwriter;
my $image = Image::Base::PNGwriter->new (-width => 1, -height => 1);

use Test::More tests => 1;
ok (1, 'Image::Base::PNGwriter load as first thing');
exit 0;
