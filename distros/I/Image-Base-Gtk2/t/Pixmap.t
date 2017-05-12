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

plan tests => 25;

use_ok ('Image::Base::Gtk2::Gdk::Pixmap');
diag "Image::Base version ", Image::Base->VERSION;


#------------------------------------------------------------------------------
# VERSION

my $want_version = 11;
is ($Image::Base::Gtk2::Gdk::Pixmap::VERSION,
    $want_version, 'VERSION variable');
is (Image::Base::Gtk2::Gdk::Pixmap->VERSION,
    $want_version, 'VERSION class method');

ok (eval { Image::Base::Gtk2::Gdk::Pixmap->VERSION($want_version); 1 },
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { Image::Base::Gtk2::Gdk::Pixmap->VERSION($check_version); 1 },
    "VERSION class check $check_version");


#------------------------------------------------------------------------------
# new()

{
  my $pixmap = Gtk2::Gdk::Pixmap->new (Gtk2::Gdk->get_default_root_window,
                                       8,9, -1);
  my $image = Image::Base::Gtk2::Gdk::Pixmap->new
    (-drawable => $pixmap);
  isa_ok ($image, 'Image::Base');
  isa_ok ($image, 'Image::Base::Gtk2::Gdk::Pixmap');

  is ($image->VERSION,  $want_version, 'VERSION object method');
  ok (eval { $image->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $image->VERSION($check_version); 1 },
      "VERSION object check $check_version");

  is ($image->get('-file'), undef, 'get() -file');
  is ($image->get('-width'),  8, 'get() -width');
  is ($image->get('-height'), 9, 'get() -height');
  cmp_ok ($image->get('-depth'), '>', 0, 'get() -depth');

  is ($image->get('-screen'),   $pixmap->get_screen,   'get() -screen');
  is ($image->get('-colormap'), $pixmap->get_colormap, 'get() -colormap');
}

{
  my $image = Image::Base::Gtk2::Gdk::Pixmap->new
    (-width  => 8,
     -height => 9,
     -depth  => 1);
  is ($image->get('-width'),  8, 'bitmap get() -width');
  is ($image->get('-height'), 9, 'bitmap get() -height');
  is ($image->get('-depth'),  1, 'bitmap get() -depth');
}


#------------------------------------------------------------------------------
# colour_to_colorobj() pixels

{
  my $pixmap = Gtk2::Gdk::Pixmap->new (Gtk2::Gdk->get_default_root_window, 10,10, -1);
  my $image = Image::Base::Gtk2::Gdk::Pixmap->new
    (-drawable => $pixmap);
  foreach my $colour ('black', 'white', '#FF00FF', '#0000AAAAbbbb') {
    my $c1 = $image->colour_to_colorobj('black');
    my $c2 = $image->colour_to_colorobj('black');
    is ($c1->pixel, $c2->pixel, "colour_to_colorobj() $colour");
  }
  {
    my $c = $image->colour_to_colorobj('set');
    is ($c->pixel, 1, "colour_to_colorobj() 'set'");
  }
  {
    my $c = $image->colour_to_colorobj('clear');
    is ($c->pixel, 0, "colour_to_colorobj() 'clear'");
  }
}

#------------------------------------------------------------------------------
# line

{
  my $pixmap = Gtk2::Gdk::Pixmap->new (Gtk2::Gdk->get_default_root_window, 10,10, -1);
  my $image = Image::Base::Gtk2::Gdk::Pixmap->new
    (-pixmap => $pixmap);
  $image->rectangle (0,0, 19,9, 'black', 1);
  $image->line (5,5, 7,7, 'white', 0);
  #   is ($image->xy (4,4), ' ');
  #   is ($image->xy (5,5), '*');
  #   is ($image->xy (5,6), ' ');
  #   is ($image->xy (6,6), '*');
  #   is ($image->xy (7,7), '*');
  #   is ($image->xy (8,8), ' ');
}
{
  my $pixmap = Gtk2::Gdk::Pixmap->new (Gtk2::Gdk->get_default_root_window, 10,10, -1);
  my $image = Image::Base::Gtk2::Gdk::Pixmap->new
    (-pixmap => $pixmap);
  $image->rectangle (0,0, 19,9, 'black', 1);
  $image->line (0,0, 2,2, 'white', 1);
  #   is ($image->xy (0,0), 'white');
  #   is ($image->xy (1,1), 'white');
  #   is ($image->xy (2,1), 'black');
  #   is ($image->xy (3,3), 'black');
}

#------------------------------------------------------------------------------
# xy

{
  my $pixmap = Gtk2::Gdk::Pixmap->new (Gtk2::Gdk->get_default_root_window, 10,10, -1);
  my $image = Image::Base::Gtk2::Gdk::Pixmap->new
    (-pixmap => $pixmap);
  $image->xy (2,2, 'black');
  $image->xy (3,3, 'white');
  #   is ($image->xy (2,2), 'black', 'xy()  ');
  #   is ($image->xy (3,3), 'white', 'xy() *');
}

#------------------------------------------------------------------------------
# rectangle

{
  my $pixmap = Gtk2::Gdk::Pixmap->new (Gtk2::Gdk->get_default_root_window, 10,10, -1);
  my $image = Image::Base::Gtk2::Gdk::Pixmap->new
    (-pixmap => $pixmap);
  $image->rectangle (0,0, 19,9, 'black', 1);
  $image->rectangle (5,5, 7,7, 'white', 0);
  #   is ($image->xy (5,5), 'white');
  #   is ($image->xy (6,6), 'black');
  #   is ($image->xy (7,6), 'white');
  #   is ($image->xy (8,8), 'black');
}
{
  my $pixmap = Gtk2::Gdk::Pixmap->new (Gtk2::Gdk->get_default_root_window, 10,10, -1);
  my $image = Image::Base::Gtk2::Gdk::Pixmap->new
    (-pixmap => $pixmap);
  $image->rectangle (0,0, 19,9, 'black', 1);
  $image->rectangle (0,0, 2,2, 'white', 1);
  #   is ($image->xy (0,0), 'white');
  #   is ($image->xy (1,1), 'white');
  #   is ($image->xy (2,1), 'white');
  #   is ($image->xy (3,3), 'black');
}

exit 0;
