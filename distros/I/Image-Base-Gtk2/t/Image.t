#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Gtk2.
#
# Image-Base-Gtk2 is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Gtk2 is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Gtk2.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';

eval { Gtk2->VERSION(1.240); 1 }
  or plan skip_all => 'due to Gtk2-Perl '.Gtk2->VERSION.', no full GdkImage until 1.240';

plan tests => 1959;

use_ok ('Image::Base::Gtk2::Gdk::Image');
diag "Image::Base version ", Image::Base->VERSION;

#------------------------------------------------------------------------------
# VERSION

my $want_version = 11;
is ($Image::Base::Gtk2::Gdk::Image::VERSION,
    $want_version, 'VERSION variable');
is (Image::Base::Gtk2::Gdk::Image->VERSION,
    $want_version, 'VERSION class method');

ok (eval { Image::Base::Gtk2::Gdk::Image->VERSION($want_version); 1 },
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { Image::Base::Gtk2::Gdk::Image->VERSION($check_version); 1 },
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# new()

{
  my $visual = Gtk2::Gdk::Visual->get_best;
  my $gdkimage = Gtk2::Gdk::Image->new ('normal', $visual, 8,9);
  my $image = Image::Base::Gtk2::Gdk::Image->new
    (-gdkimage => $gdkimage);
  isa_ok ($image, 'Image::Base');
  isa_ok ($image, 'Image::Base::Gtk2::Gdk::Image');

  is ($image->VERSION,  $want_version, 'VERSION object method');
  ok (eval { $image->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $image->VERSION($check_version); 1 },
      "VERSION object check $check_version");

  is ($image->get('-file'), undef, 'get() -file');
  is ($image->get('-width'),  8, 'get() -width');
  is ($image->get('-height'), 9, 'get() -height');
  cmp_ok ($image->get('-depth'), '>', 0, 'get() -depth');
  is ($image->get('-depth'), $visual->depth, 'get() -depth per visual');
  is ($image->get('-colormap'), $gdkimage->get_colormap, 'get() -colormap');
}

SKIP: {
  my $depth = 1;
  my $visual = Gtk2::Gdk::Visual->get_best_with_depth ($depth);
  if (! $visual) {
    skip 'No bitmap visual -- strange', 3;
  }
  my $gdkimage = Gtk2::Gdk::Gdkimage->new ('fastest', $visual, 8,9);
  my $image = Image::Base::Gtk2::Gdk::Image->new
    (-gdkimage => $gdkimage);
  isa_ok ($image, 'Image::Base');
  isa_ok ($image, 'Image::Base::Gtk2::Gdk::Image');
  is ($image->get('-depth'),  1, 'get() -depth bitmap');
}


#------------------------------------------------------------------------------
# xy

{
  my $image = Image::Base::Gtk2::Gdk::Image->new
    (-width => 20,
     -height => 10);
  $image->xy (2,2, 0);
  $image->xy (3,3, 1);
  is ($image->xy (2,2), 0, 'xy() zero');
  is ($image->xy (3,3), 1, 'xy() one');
}
{
  my $colormap = Gtk2::Gdk::Colormap->get_system;
  my $image = Image::Base::Gtk2::Gdk::Image->new
    (-width => 20,
     -height => 10,
     -colormap => $colormap);
  $image->xy (2,2, 'black');
  $image->xy (3,3, 'white');
  is ($image->xy (2,2), '#000000000000', 'xy() zero');
  is ($image->xy (3,3), '#FFFFFFFFFFFF', 'xy() one');
}

#------------------------------------------------------------------------------
# line

{
  my $image = Image::Base::Gtk2::Gdk::Image->new
    (-width => 20,
     -height => 10);
  $image->rectangle (0,0, 19,9, 0, 1);
  $image->line (5,5, 7,7, 1, 0);
  is ($image->xy (4,4), 0);
  is ($image->xy (5,5), 1);
  is ($image->xy (5,6), 0);
  is ($image->xy (6,6), 1);
  is ($image->xy (7,7), 1);
  is ($image->xy (8,8), 0);
}
{
  my $colormap = Gtk2::Gdk::Colormap->get_system;
  my $image = Image::Base::Gtk2::Gdk::Image->new
    (-width => 20,
     -height => 10,
     -colormap => $colormap);
  $image->rectangle (0,0, 19,9, 0, 'black');
  $image->line (0,0, 2,2, 'white');
  is ($image->xy (0,0), '#FFFFFFFFFFFF');
  is ($image->xy (1,1), '#FFFFFFFFFFFF');
  is ($image->xy (2,1), '#000000000000');
  is ($image->xy (3,3), '#000000000000');
}

#------------------------------------------------------------------------------
# rectangle

{
  my $image = Image::Base::Gtk2::Gdk::Image->new
    (-width => 20,
     -height => 10);
  $image->rectangle (0,0, 19,9, 0, 1); # zero filled
  $image->rectangle (5,5, 7,7,  1, 0); # one unfilled
  is ($image->xy (5,5), 1);
  is ($image->xy (6,6), 0);
  is ($image->xy (7,6), 1);
  is ($image->xy (8,8), 0);
}
{
  my $colormap = Gtk2::Gdk::Colormap->get_system;
  my $image = Image::Base::Gtk2::Gdk::Image->new
    (-width => 20,
     -height => 10,
     -colormap => $colormap);
  $image->rectangle (0,0, 19,9, 'black');
  $image->rectangle (0,0, 2,2,  'white', 1); # filled
  is ($image->xy(0,0), '#FFFFFFFFFFFF');
  is ($image->xy(1,1), '#FFFFFFFFFFFF');
  is ($image->xy(2,1), '#FFFFFFFFFFFF');
  is ($image->xy(3,3), '#000000000000');
}

#------------------------------------------------------------------------------

# SKIP: {
#   my $visual = Gtk2::Gdk::Visual->get_best_with_depth (1);
#   if (! $visual) {
#     skip 'No monochrome visual', 3;
#   }
#   require MyTestImageBase;
#   my $image = Image::Base::Gtk2::Gdk::Image->new
#     (-width => 21,
#      -height => 10,
#      -visual => $visual);
#   local $MyTestImageBase::white = 1;
#   local $MyTestImageBase::black = 0;
#   MyTestImageBase::check_image ($image);
# }
{
  require MyTestImageBase;
  my $colormap = Gtk2::Gdk::Colormap->get_system;
  my $image = Image::Base::Gtk2::Gdk::Image->new
    (-width => 21,
     -height => 10,
     -colormap => $colormap);
  no warnings 'once';
  local $MyTestImageBase::white = 'white';
  local $MyTestImageBase::black = 'black';
  MyTestImageBase::check_image ($image);
}

exit 0;
