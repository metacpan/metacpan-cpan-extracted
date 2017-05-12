#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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
  # jpeg compression on save()
  #
  require Image::Base::GD;
  my $image = Image::Base::GD->new
    (-width => 200, -height => 100,
     -file_format => 'jpeg');
  $image->ellipse (1,1, 100,50, 'green');
  $image->ellipse (100,50, 199,99, 'orange');
  $image->line (1,99, 199,0, 'red');
  $image->set (-quality_percent => 1);
  $image->save ('/tmp/x-001.jpeg');
  $image->set (-quality_percent => 100);
  $image->save ('/tmp/x-100.jpeg');
  system "ls -l /tmp/x*";
  exit 0;
}

{
  my $gd = GD::Image->new(1,1) || die;
  my $white = $gd->colorAllocate(255,255,255);
  my $black = $gd->colorAllocate(0,0,0);
  $gd->rectangle(0,0,1,1,$white);
  $gd->rectangle(1,0,1,1,$black);
  ### bytes: $gd->gif
  open my $fh, '>', 't/GD-format-gif.gif' or die;
  print $fh $gd->gif or die;
  close $fh or die;
  exit 0;
}
{
  my $gd = GD::Image->new(1,1) || die;
  my $white = $gd->colorAllocate(255,255,255);
  $gd->rectangle(0,0,1,1,$white);
  ### bytes: $gd->jpeg
  open my $fh, '>', 't/GD-jpeg.jpg' or die;
  print $fh $gd->jpeg or die;
  close $fh or die;
  exit 0;
}


