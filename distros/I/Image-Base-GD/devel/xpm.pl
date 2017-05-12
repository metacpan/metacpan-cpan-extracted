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

# uncomment this to run the ### lines
use Devel::Comments;

{
  require Image::Xpm;
  my $image = Image::Xpm->new(-width=>2,-height=>1);
  $image->xy(0,0,'#FFFFFF');
  $image->xy(1,0,'#000000');
  $image->save('t/GD-format-xpm.xpm');
  exit 0;
}
{
  require Image::Xbm;
  my $image = Image::Xbm->new(-width=>2,-height=>1);
  $image->xybit(0,0, 0);
  $image->xybit(1,0, 1);
  $image->save('t/GD-format-xbm.xbm');
  exit 0;
}
{
  open my $fh, '<', 't/GD-format-xpm.xpm' or die;
  my $gd = GD::Image->newFromXpm($fh);
  ### $gd
  exit 0;
}
