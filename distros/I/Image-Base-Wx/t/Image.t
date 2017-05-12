#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Image-Base-Wx.
#
# Image-Base-Wx is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Wx is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Wx.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

eval { require Wx }
  or plan skip_all => "due to Wx display not available -- $@";

plan tests => 2519;

use_ok ('Image::Base::Wx::Image');
diag "Image::Base version ", Image::Base->VERSION;

# uncomment this to run the ### lines
#use Smart::Comments;


#------------------------------------------------------------------------------
# VERSION

my $want_version = 4;
is ($Image::Base::Wx::Image::VERSION,
    $want_version, 'VERSION variable');
is (Image::Base::Wx::Image->VERSION,
    $want_version, 'VERSION class method');

ok (eval { Image::Base::Wx::Image->VERSION($want_version); 1 },
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { Image::Base::Wx::Image->VERSION($check_version); 1 },
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# new()

{
  my $image = Image::Base::Wx::Image->new
    (-width => 21, -height => 10);
  isa_ok ($image, 'Image::Base');
  isa_ok ($image, 'Image::Base::Wx::Image');

  is ($image->VERSION,  $want_version, 'VERSION object method');
  ok (eval { $image->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $image->VERSION($check_version); 1 },
      "VERSION object check $check_version");

  is ($image->get('-file'), undef, 'get() -file');
  is ($image->get('-width'),  21, 'get() -width');
  is ($image->get('-height'), 10, 'get() -height');
  # cmp_ok ($image->get('-depth'), '>', 0, 'get() -depth');
}

{
  my $wximage = Wx::Image->new(32,16);
  my $image = Image::Base::Wx::Image->new
    (-wximage => $wximage);
  isa_ok ($image, 'Image::Base');
  isa_ok ($image, 'Image::Base::Wx::Image');

  is ($image->get('-file'), undef, 'get() -file');
  is ($image->get('-width'),  32, 'get() -width');
  is ($image->get('-height'), 16, 'get() -height');
  # is ($image->get('-depth'),  1, 'get() -depth');
}


#------------------------------------------------------------------------------
# new() clone

{
  my $image = Image::Base::Wx::Image->new
    (-width => 21, -height => 10);
  my $i2 = $image->new;
  $image->xy(0,0, '#000000');
  $i2->xy(0,0, '#FFFFFF');
  is ($image->xy(0,0), '#000000');
  is ($i2->xy(0,0), '#FFFFFF');
}


#------------------------------------------------------------------------------
# load()

# diag "image handlers:";
# foreach my $handler (Wx::GetHandlers()) {
#   diag "  $handler";
# }
Wx::InitAllImageHandlers();

{
  my $image = Image::Base::Wx::Image->new;
  eval { $image->load('nosuchfile') };
  my $err = $@;
  diag "load error as expected: ",$err;
  like ($err, qr/Error|Cannot/i,
        'load(nosuchfile)');
}

#------------------------------------------------------------------------------
# save()

# Wx::InitAllImageHandlers();
{
  my $filename = 'tempfile.bmp';
  my $image = Image::Base::Wx::Image->new
    (-width => 20, -height => 10,
     -file_format => 'bmp');
  {
    $image->save($filename);
    unlink $filename;
  }
  {
    my $image = Image::Base::Wx::Image->new
      (-width => 10, -height => 10, -file_format => 'bmp');
    eval { $image->save('/no/such/direct/ory/test.bmp') };
    my $err = $@;
    diag "save error as expected: ",$err;
    like ($err, qr/Error|Cannot/i,
          'save(no/such/dir)');
  }
}

#------------------------------------------------------------------------------
# XPM -hotx, -hoty

# Don't seem to get hotspot from xpm ...
# {
#   Wx::InitAllImageHandlers();
#   my $str = <<'HERE';
# /* XPM */
# static char *x[] = {
# "2 3 1 1 1 2",
# "  c white",
# "  ",
# "  ",
# "  "
# };
# HERE
#   require File::Temp;
#   my $fh = File::Temp->new;
#   my $filename = $fh->filename;
#   binmode $fh or die;
#   print $fh $str or die;
#   close $fh or die;
# 
#   my $image = Image::Base::Wx::Image->new;
#   $image->load ($filename);
#   is ($image->get('-width'),  2, 'get() xpm -width');
#   is ($image->get('-height'), 3, 'get() xpm -height');
#   is ($image->get('-hotx'), 1, 'get() xpm -hotx');
#   is ($image->get('-hoty'), 2, 'get() xpm -hoty');
# 
#   $image->set('-hotx', 4);
#   $image->set('-hoty', 5);
#   is ($image->get('-hotx'), 4, 'set() -hotx');
#   is ($image->get('-hoty'), 5, 'set() -hoty');
# }

#------------------------------------------------------------------------------
# CUR load -hotx, -hoty

{
  Wx::InitAllImageHandlers();
  my $str =
    ("\x{00}\x{00}\x{02}\x{00}\x{01}\x{00}\x{02}\x{03}"
     . "\x{00}\x{00}\x{00}\x{00}\x{01}\x{00}\x{4C}\x{00}"
     . "\x{00}\x{00}\x{16}\x{00}\x{00}\x{00}\x{28}\x{00}"
     . "\x{00}\x{00}\x{02}\x{00}\x{00}\x{00}\x{06}\x{00}"
     . "\x{00}\x{00}\x{01}\x{00}\x{18}\x{00}\x{00}\x{00}"
     . "\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}"
     . "\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}"
     . "\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{AA}"
     . "\x{FF}\x{00}\x{AA}\x{FF}\x{00}\x{00}\x{00}\x{AA}"
     . "\x{FF}\x{00}\x{AA}\x{FF}\x{00}\x{00}\x{00}\x{AA}"
     . "\x{FF}\x{00}\x{AA}\x{FF}\x{00}\x{00}\x{00}\x{00}"
     . "\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}"
     . "\x{00}\x{00}");
  require File::Temp;
  my $fh = File::Temp->new;
  my $filename = $fh->filename;
  binmode $fh or die;
  print $fh $str or die;
  close $fh or die;

  my $image = Image::Base::Wx::Image->new
    (-file => $filename);
  is ($image->get('-width'),  2, 'get() cur -width');
  is ($image->get('-height'), 3, 'get() cur -height');
  is ($image->get('-hotx'), 0, 'get() cur -hotx');
  is ($image->get('-hoty'), 1, 'get() cur -hoty');
}

#------------------------------------------------------------------------------
# CUR save then load -hotx, -hoty

{
  Wx::InitAllImageHandlers();
  require File::Temp;
  my $fh = File::Temp->new;
  my $filename = $fh->filename;
  {
    my $image = Image::Base::Wx::Image->new
      (-width => 2,
       -height => 3,
       -hotx => 1,
       -hoty => 2,
       -file_format => 'CUR');
    $image->save ($filename);
  }
  ok (-f $filename);
  {
    my $image = Image::Base::Wx::Image->new
      (-file => $filename);
    is ($image->get('-width'),  2, 'get() cur -width');
    is ($image->get('-height'), 3, 'get() cur -height');
    is ($image->get('-hotx'), 1, 'get() cur -hotx');
    is ($image->get('-hoty'), 2, 'get() cur -hoty');
  }
}

#------------------------------------------------------------------------------
# colour_to_rgb()

{
  my $image = Image::Base::Wx::Image->new;
  ### rgb: $image->colour_to_rgb('black')

  is_deeply ([$image->colour_to_rgb('black')], [0,0,0]);
  is_deeply ([$image->colour_to_rgb('white')], [255,255,255]);

  is_deeply ([$image->colour_to_rgb('#000')], [0,0,0]);
  is_deeply ([$image->colour_to_rgb('#000000')], [0,0,0]);
  is_deeply ([$image->colour_to_rgb('#000000000')], [0,0,0]);
  is_deeply ([$image->colour_to_rgb('#000000000000')], [0,0,0]);

  is_deeply ([$image->colour_to_rgb('#0F0')], [0,255,0]);
  is_deeply ([$image->colour_to_rgb('#00FF00')], [0,255,0]);
  is_deeply ([$image->colour_to_rgb('#000FFF000')], [0,255,0]);
  is_deeply ([$image->colour_to_rgb('#0000FFFF0000')], [0,255,0]);
  is_deeply ([$image->colour_to_rgb('#0000ffff0000')], [0,255,0]);
}

#------------------------------------------------------------------------------
# line

{
  my $image = Image::Base::Wx::Image->new
    (-width => 21, -height => 10);
  $image->rectangle (0,0, 20,9, 'black', 1);
  $image->line (5,5, 7,7, 'white', 0);
  is ($image->xy (4,4), '#000000');
  is ($image->xy (5,5), '#FFFFFF');
  is ($image->xy (5,6), '#000000');
  is ($image->xy (6,6), '#FFFFFF');
  is ($image->xy (7,7), '#FFFFFF');
  is ($image->xy (8,8), '#000000');
  # require MyTestImageBase;
  # MyTestImageBase::dump_image($image);
}
{
  my $image = Image::Base::Wx::Image->new
    (-width => 21, -height => 10);
  $image->rectangle (0,0, 20,9, 'black', 1);
  $image->line (0,0, 2,2, 'white', 1);
  is ($image->xy (0,0), '#FFFFFF');
  is ($image->xy (1,1), '#FFFFFF');
  is ($image->xy (2,1), '#000000');
  is ($image->xy (3,3), '#000000');
}

#------------------------------------------------------------------------------
# xy

{
  my $image = Image::Base::Wx::Image->new
    (-width => 21, -height => 10);
  $image->rectangle (0,0, 20,9, 'black', 1);
  $image->xy (2,2, 'black');
  $image->xy (3,3, 'white');
  $image->xy (4,4, '#ffffff');
  is ($image->xy (2,2), '#000000', 'xy()  ');
  is ($image->xy (3,3), '#FFFFFF', 'xy() *');
  is ($image->xy (4,4), '#FFFFFF', 'xy() *');
}

#------------------------------------------------------------------------------
# rectangle

{
  my $image = Image::Base::Wx::Image->new
    (-width => 21, -height => 10);
  $image->rectangle (0,0, 20,9, 'black', 1);
  $image->rectangle (5,5, 7,7, 'white', 0);
  is ($image->xy (5,5), '#FFFFFF');
  is ($image->xy (6,6), '#000000');
  is ($image->xy (7,6), '#FFFFFF');
  is ($image->xy (8,8), '#000000');
  # require MyTestImageBase;
  # MyTestImageBase::dump_image($image);
}
{
  my $image = Image::Base::Wx::Image->new
    (-width => 21, -height => 10);
  $image->rectangle (0,0, 20,9, 'black', 1);
  $image->rectangle (0,0, 2,2, '#FFFFFF', 1);
  is ($image->xy (0,0), '#FFFFFF');
  is ($image->xy (1,1), '#FFFFFF');
  is ($image->xy (2,1), '#FFFFFF');
  is ($image->xy (3,3), '#000000');
}

#------------------------------------------------------------------------------
# diamond()

{
  my $image = Image::Base::Wx::Image->new
    (-width => 21, -height => 10);
  $image->rectangle (0,0, 20,9, 'black', 1);
  $image->diamond (0,0, 20,9, 'black', 1);
  $image->diamond (5,5, 7,7, 'white', 0);
}

#------------------------------------------------------------------------------
# ellipse()

{
  my $image = Image::Base::Wx::Image->new
    (-width => 21, -height => 10);
  $image->rectangle (0,0, 20,9, 'black', 1);
  $image->ellipse (0,0, 20,9, 'black', 1);
  $image->ellipse (5,5, 7,7, 'white', 0);
}

#------------------------------------------------------------------------------

{
  require MyTestImageBase;
  my $image = Image::Base::Wx::Image->new
    (-width => 21, -height => 10);

  local $MyTestImageBase::white;
  local $MyTestImageBase::black;
  $MyTestImageBase::white = 'white';
  $MyTestImageBase::black = 'black';

  # require MyTestImageBase;
  # MyTestImageBase::dump_image($image);

  MyTestImageBase::check_image ($image);
  MyTestImageBase::check_diamond ($image);
}

exit 0;
