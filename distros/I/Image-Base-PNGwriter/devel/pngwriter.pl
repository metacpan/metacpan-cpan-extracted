#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
# use blib "$ENV{HOME}/perl/image/Image-PNGwriter-0.01/blib";

# uncomment this to run the ### lines
use Devel::Comments;


{
  # rectangle off-screen

  require Image::Base::PNGwriter;
  my $image = Image::Base::PNGwriter->new (-width => 50, -height => 20);
  $image->rectangle (0,0, 49,29, 'black', 1);

  $image->rectangle (-10,-10,6,6, 'white', 1);

  $image->save('/tmp/x.png');
  system ("convert  -monochrome /tmp/x.png /tmp/x.xpm && cat /tmp/x.xpm");
  exit 0;
}

{
  require Image::PNGwriter;
  exit 0;
}

{
  require Image::Base::PNGwriter;
  my $image = Image::Base::PNGwriter->new (-width => 50, -height => 20);
  $image->rectangle (0,0, 49,29, 'black');

  $image->diamond (1,1,6,6, 'white');
  $image->diamond (11,1,16,6, 'white', 1);
  $image->diamond (1,10,7,16, 'white');
  $image->diamond (11,10,17,16, 'white', 1);

  $image->save('/tmp/x.png');
  system ("convert  -monochrome /tmp/x.png /tmp/x.xpm && cat /tmp/x.xpm");
  exit 0;
}

{
  my $class;
  $class = 'Image::Base::PNGwriter';
  eval "require $class" or die;
  my $image = $class->new (-width  => 10,
                           -height => 10);
  $image->rectangle (0,0, 9,9, '#000000');
  my $colour = $image->xy(0,0);
  ### $colour
  exit 0;
}

{
  require Image::PNGwriter;
  my $pw = Image::PNGwriter->new(50,30,0,'/tmp/x.png');
  my $r = 0;
  #  $pw->plot (6,6, .5,.5,.5);
  # $pw->circle (6,6, $r, 1,1,1);

  require Image::Base::PNGwriter;
  my $image = Image::Base::PNGwriter->new(-pngwriter => $pw);
  $image->rectangle (0,0,49,19, '#000000');
  #   $image->ellipse (20,        20-2-(2*$r),
  #                    20+(2*$r), 20-2,
  #                    '#00FF00');

  $pw->filleddiamond (18,16, 8,8, 1,1,1);
  $pw->diamond (33,16, 8,8, 1,1,1);

  # $image->diamond (1,1, 6,6, 'white', 1);

  # $image->ellipse (1,11, 6,13,
  #                  '#00FF00');

  $pw->write_png;
  system ("convert /tmp/x.png /tmp/x.xpm && cat /tmp/x.xpm");

  $image->xy (40,20-2, '#AABBCC');
  $image->xy (40,20-2-(2*$r), '#AABBCC');

  print "done\n";
  exit 0;
}

{
  require Image::PNGwriter;
  my $pw = Image::PNGwriter->new(100,100,0,'/tmp/x.png');
  my $copy = $pw->CLONE;
  # my $copy = Image::PNGwriter->new($pw);
  print "done\n";
  exit 0;
}

{
  require Image::PNGwriter;
  my $pw = Image::PNGwriter->new(1,1,
                                 0,
                                 '/dev/null');
  $pw->setcompressionlevel(9);
  $pw->square(5,5, 7,7, 1,1,1);
  #  $pw->resize (9,9);
  $pw->pngwriter_rename ('/tmp/x.png');
  $pw->write_png;

  {
    require Image::ExifTool;
    my $info = Image::ExifTool::ImageInfo ('/tmp/x.png');
    require Data::Dumper;
    print Data::Dumper->new([\$info],['info'])->Dump;
  }
  print "done\n";
  exit 0;
}
{
  my $class;
  $class = 'Image::Xpm';
  $class = 'Image::Base::PNGwriter';
  eval "require $class" or die;
  my $image = $class->new (-width  => 10,
                           -height => 10,
                           -author => 'Some Body');
  $image->rectangle (0,0, 5,5, '#FF00FF');
  $image->line (0,0, 5,5, '#FF00FF');
  $image->save ('/tmp/x.png');
  exit 0;
}

{
  require Image::PNGwriter;
  print Image::PNGwriter->VERSION,"\n";
  print Image::PNGwriter->version,"\n";
  my $pw = Image::PNGwriter->new(10,10,
                                        0,
                                        '/tmp/nosuchdir/x.png');
  $pw->square(5,5, 7,7, 1,1,1);
  print $pw->dread(6,6, 1),"\n";
  $pw->write_png;
  print "done\n";
  exit 0;
}
{
  require Image::PNGwriter;
  my $pw = Image::PNGwriter->new(10,10,
                                        0,
                                        '/tmp/x.png');
  $pw->plot(1,1, 0x11, 0x22, 0x33);
  print $pw->dread(1,1, 0),"\n";
  print $pw->dread(1,1, 1),"\n";
  print $pw->dread(1,1, 2),"\n";
  print $pw->dread(1,1, 3),"\n";
  $pw->write_png;
  exit 0;
}
{
  require Image::PNGwriter;
  my $filename = '/tmp/zz.png';
  my $pw = Image::PNGwriter->new (100,100, 0, $filename);
  $pw->pngwriter_rename($filename);
  substr ($filename,5,2, 'WW');
  $pw->write_png;
  print $filename,"\n";
  exit 0;
}
{
  require Image::PNGwriter;
  my $pw = Image::PNGwriter->new(100,100,
                                        0,
                                        '/tmp/zz.png');
  $pw->readfromfile ('/tmp/x.png');
  # $pw->filledsquare(10,10, 20,20, 255,255,255);
  $pw->write_png;
  exit 0;
}
