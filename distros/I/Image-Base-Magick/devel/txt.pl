#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Image-Base-Magick.
#
# Image-Base-Magick is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Magick is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Magick.  If not, see <http://www.gnu.org/licenses/>.

require 5;
use strict;

use Smart::Comments;

{
  require Image::Base::Magick;
  my $image = Image::Base::Magick->new (-width => 20,
                                        -height => 10,
                                        -file_format => 'xpm');

  # $image->load('/dev/null');
  # $image->set(-file_format => 'PNG');
  $image->ellipse (1,1, 18,8, 'white', 1);
  $image->save('/dev/stdout');
  exit 0;
}

