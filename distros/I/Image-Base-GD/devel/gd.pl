#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

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

use Smart::Comments;


{
  # 2x2 palletted bad for "chimera2"
  require GD;
  print GD->VERSION,"\n";
  my $gd = GD::Image->new (2,2);
  print $gd->colorAllocate(0,0,0),"\n";
  open FH, '>', '/tmp/gd.png' or die;
  print FH $gd->png or die;
  close FH or die;
  exit 0;
}

{
  # rectangle off-screen

  require Image::Base::GD;
  my $w = 30;
  my $h = 30;
  my $image = Image::Base::GD->new (-width => $w, -height => $h);
  $image->rectangle (0,0, $w-1,$h-1, 'black', 1); # filled

  # $image->line (-41,15,-34,22, 'white');
  $image->ellipse (-41,15, -34,22, 'white', 1);
  # $image->xy (-38,15, 'white');

  #-10,-10,6,6, 'white',1);
  #  $image->rectangle (8,8, 100,100, 'white',1);

  $image->save('/tmp/x.png');
  system ("convert  -monochrome /tmp/x.png /tmp/x.xpm && cat /tmp/x.xpm");

  exit 0;
}

{
  require Image::Base::GD;
  require Image::Xpm;
  my $image = Image::Base::GD->new (-width => 50, -height => 20);
  $image->rectangle (0,0, 49,29, 'black');

  $image->diamond (1,1,6,6, 'white');
  $image->diamond (11,1,16,6, 'white', 1);
  $image->diamond (1,10,7,16, 'white');
  $image->diamond (11,10,17,16, 'white', 1);

  my $gd = $image->get('-gd');
  $gd->setThickness(1);

  # $gd->ellipse (5,5, 6,6, $image->colour_to_index('white'));
  # $gd->rectangle (10,12, 14,12, $image->colour_to_index('white'));

  $image->save('/tmp/x.png');
  system ("convert  -monochrome /tmp/x.png /tmp/x.xpm && cat /tmp/x.xpm");

  exit 0;
}

{
  require FindBin;
  require File::Spec;
  print "bin directory: ", $FindBin::Bin, "\n";
  my $filename = File::Spec->catfile($FindBin::Bin,
                                     File::Spec->updir, 't', 'empty.dat');
  require Image::Base::GD;
  my $image = Image::Base::GD->new (-file => $filename);
  exit 0;
}
{
  require Image::Base::GD;
  require Image::Xpm;
  my $image = Image::Base::GD->new (-width => 50, -height => 15);
  $image->rectangle (0,0, 49,29, 'black');
  # $image->rectangle (3,3, 7,7, 'white');
  # $image->ellipse (0,0, 11,10, 'white');

  my $gd = $image->get('-gd');
  $gd->setThickness(1);

  # $gd->ellipse (5,5, 6,6, $image->colour_to_index('white'));
  $gd->rectangle (10,12, 14,12, $image->colour_to_index('white'));

  $image->save('/tmp/x.png');
  system ("convert  -monochrome /tmp/x.png /tmp/x.xpm && cat /tmp/x.xpm");

  exit 0;
}

{
  require GD;
  print GD->VERSION,"\n";
  my $gd = GD::Image->new (100,100, 1);

#   my $index1 = $gd->colorAllocate(1,2,3);
#   print "$index1\n";

  my $index_t = $gd->colorAllocateAlpha(1,2,3, 1);
  printf "index_t %X\n", $index_t;

  my $index2 = $gd->colorAllocate(0xFF,0xAA,0xAA);
  printf "index2  %X\n", $index2;

  $gd->alphaBlending(0);
  $gd->setPixel (20, 20, $index2);
  $gd->setPixel (20, 20, $index_t);
  my $got = $gd->getPixel(20, 20);
  printf "got %X\n", $got;
  exit 0;
}

{
  require GD;
  print GD->VERSION,"\n";
  my $gd = GD::Image->new (100,100);
  foreach my $i (1 .. 259) {
    print $gd->colorAllocate(0,0,0),"\n";
  }
  exit 0;
}





{
  require GD;
  # print gdTransparent();
  print GD::gdTransparent();
  exit 0;
}

