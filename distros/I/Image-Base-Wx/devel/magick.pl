#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Wx.
#
# Image-Base-Wx is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Wx is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Wx.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use Wx;

{
  # Wx::Perl::Imagick
  require Wx::Perl::Imagick;
  my $wximage = Wx::Perl::Imagick->new (20, 10);
  require Image::Base::Wx::Image;
  my $image = Image::Base::Wx::Image->new
    (-wximage => $wximage,
     -file_format => 'xpm');
  ### $image
  # $image->rectangle (10,10, 50,50, 'orange');
   $image->xy (10,5, 'orange');
  $image->save('/tmp/x.xpm');
  system ('cat /tmp/x.xpm');
  exit 0;
}

