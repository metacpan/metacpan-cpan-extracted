#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Image-Base-Other.
#
# Image-Base-Other is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Other.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Smart::Comments;

{
  require Image::Base::Text;
  print "Image::Base version ", Image::Base->VERSION, "\n";
  my $image = Image::Base::Text->new (-width => 30, -height => 30);

  # $image->rectangle (0,0,30,30, ' ', 1); # fill

   $image->line (3,3, 9,3, 'x'); # horizontal

  # $image->rectangle (-10,-10, 10,10, 'x', 0);
  # $image->rectangle (20,0, 22,0, 'z', 0);
  $image->save('/dev/stdout');
  exit 0;
}
