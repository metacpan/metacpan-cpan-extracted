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
  my $gd = GD::Image->new(2,1) || die;
  my $black = $gd->colorAllocate(0,0,0);
  my $white = $gd->colorAllocate(255,255,255);
  ### $black
  ### $white
  # my $red = $gd->colorAllocate(255,0,0);

  # $gd->rectangle(0,0,99,49,$white);
  #
  # my $black = $gd->colorAllocate(0,0,0);
  # $gd->rectangle(10,10, 50,20, $black);

  # my $black = $gd->colorAllocate(0,0,0);
  # $gd->rectangle(10,10, 50,20, $black);

  $gd->setPixel(0,0,$white);
  $gd->setPixel(1,0,$black);

  my $filename = '/tmp/foo.wbmp';
  open my $fh, '>', $filename or die;
  print $fh $gd->wbmp($white) or die;
  close $fh or die;
}
{
  open my $fh, '<', '/tmp/foo.wbmp' or die;
  my $gd = GD::Image->_newFromWBMP($fh);
  my $black = $gd->colorExact(0,0,0);
  my $white = $gd->colorExact(255,255,255);
  # my $black = $gd->colorAllocate(0,0,0);
  # my $white = $gd->colorAllocate(255,255,255);
  ### $black
  ### $white

  {
    my $p = $gd->getPixel(0,0);
    my @rgb = $gd->rgb($p);
    ### $p
    ### @rgb
  }
  {
    my $p = $gd->getPixel(1,0);
    my @rgb = $gd->rgb($p);
    ### $p
    ### @rgb
  }
}
