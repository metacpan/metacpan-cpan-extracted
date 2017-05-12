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

plan tests => 4420;

use_ok ('Image::Base::Gtk2::Gdk::Drawable');
diag "Image::Base version ", Image::Base->VERSION;
MyTestHelpers::glib_gtk_versions();

if (! eval { require X11::Protocol; 1 }) {
  diag "No X11::Protocol for server info";
} else {
  my $display_name = Gtk2::Gdk->get_display;
  my $X = eval { X11::Protocol->new($display_name) };
  if (! $X) {
    diag "Cannot open display for server info: $@";
  } else {
    MyTestHelpers::X11_server_info($X);
  }
}


#------------------------------------------------------------------------------
# VERSION

my $want_version = 11;
is ($Image::Base::Gtk2::Gdk::Drawable::VERSION,
    $want_version, 'VERSION variable');
is (Image::Base::Gtk2::Gdk::Drawable->VERSION,
    $want_version, 'VERSION class method');

ok (eval { Image::Base::Gtk2::Gdk::Drawable->VERSION($want_version); 1 },
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { Image::Base::Gtk2::Gdk::Drawable->VERSION($check_version); 1 },
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# new()

{
  my $pixmap = Gtk2::Gdk::Pixmap->new (Gtk2::Gdk->get_default_root_window,
                                       8,9, -1);
  my $image = Image::Base::Gtk2::Gdk::Drawable->new
    (-drawable => $pixmap);
  isa_ok ($image, 'Image::Base');
  isa_ok ($image, 'Image::Base::Gtk2::Gdk::Drawable');

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
  my $pixmap = Gtk2::Gdk::Pixmap->new (Gtk2::Gdk->get_default_root_window,
                                       8,9, 1);
  my $image = Image::Base::Gtk2::Gdk::Drawable->new
    (-drawable => $pixmap);
  isa_ok ($image, 'Image::Base');
  isa_ok ($image, 'Image::Base::Gtk2::Gdk::Drawable');
  is ($image->get('-depth'),  1, 'get() -depth');
}


#------------------------------------------------------------------------------
# colour_to_pixel

{
  my $pixmap = Gtk2::Gdk::Pixmap->new (Gtk2::Gdk->get_default_root_window, 10,10, -1);
  my $image = Image::Base::Gtk2::Gdk::Drawable->new
    (-drawable => $pixmap);
  foreach my $colour ('black', 'white', '#FF00FF', '#0000AAAAbbbb') {
    my $c1 = $image->colour_to_colorobj($colour);
    my $c2 = $image->colour_to_colorobj($colour);
    is ($c1->pixel, $c2->pixel, "colour_to_colorobj() pixels $colour");
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
  my $pixmap = Gtk2::Gdk::Pixmap->new (Gtk2::Gdk->get_default_root_window,
                                       20,10, -1);
  my $image = Image::Base::Gtk2::Gdk::Drawable->new
    (-pixmap => $pixmap);
  $image->rectangle (0,0, 19,9, 'black', 1);
  $image->line (5,5, 7,7, 'white', 0);
  is ($image->xy (4,4), '#000000');
  is ($image->xy (5,5), '#FFFFFF');
  is ($image->xy (5,6), '#000000');
  is ($image->xy (6,6), '#FFFFFF');
  is ($image->xy (7,7), '#FFFFFF');
  is ($image->xy (8,8), '#000000');
}
{
  my $pixmap = Gtk2::Gdk::Pixmap->new (Gtk2::Gdk->get_default_root_window,
                                       20,10, -1);
  my $image = Image::Base::Gtk2::Gdk::Drawable->new
    (-pixmap => $pixmap);
  $image->rectangle (0,0, 19,9, 'black', 1);
  $image->line (0,0, 2,2, 'white', 1);
  is ($image->xy (0,0), '#FFFFFF');
  is ($image->xy (1,1), '#FFFFFF');
  is ($image->xy (2,1), '#000000');
  is ($image->xy (3,3), '#000000');
}

#------------------------------------------------------------------------------
# xy

{
  my $pixmap = Gtk2::Gdk::Pixmap->new (Gtk2::Gdk->get_default_root_window,
                                       10,10, -1);
  my $image = Image::Base::Gtk2::Gdk::Drawable->new
    (-pixmap => $pixmap);
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
  my $pixmap = Gtk2::Gdk::Pixmap->new (Gtk2::Gdk->get_default_root_window,
                                       20,10, -1);
  my $image = Image::Base::Gtk2::Gdk::Drawable->new
    (-pixmap => $pixmap);
  $image->rectangle (0,0, 19,9, 'black', 1);
  $image->rectangle (5,5, 7,7, 'white', 0);
  is ($image->xy (5,5), '#FFFFFF');
  is ($image->xy (6,6), '#000000');
  is ($image->xy (7,6), '#FFFFFF');
  is ($image->xy (8,8), '#000000');
}
{
  my $pixmap = Gtk2::Gdk::Pixmap->new (Gtk2::Gdk->get_default_root_window,
                                       20,10, -1);
  my $image = Image::Base::Gtk2::Gdk::Drawable->new
    (-pixmap => $pixmap);
  $image->rectangle (0,0, 19,9, 'black', 1);
  $image->rectangle (0,0, 2,2, '#FFFFFF', 1);
  is ($image->xy (0,0), '#FFFFFF');
  is ($image->xy (1,1), '#FFFFFF');
  is ($image->xy (2,1), '#FFFFFF');
  is ($image->xy (3,3), '#000000');
}

#------------------------------------------------------------------------------

{
  require MyTestImageBase;
  my $bitmap = Gtk2::Gdk::Pixmap->new (Gtk2::Gdk->get_default_root_window,
                                       21,10, 1);
  my $image = Image::Base::Gtk2::Gdk::Drawable->new
    (-drawable => $bitmap);
  local $MyTestImageBase::white = 1;
  local $MyTestImageBase::black = 0;
  MyTestImageBase::check_image ($image);
}
{
  require MyTestImageBase;
  my $pixmap = Gtk2::Gdk::Pixmap->new (Gtk2::Gdk->get_default_root_window,
                                       21,10, -1);
  $pixmap->set_colormap (Gtk2::Gdk->get_default_root_window->get_colormap);
  my $image = Image::Base::Gtk2::Gdk::Drawable->new
    (-drawable => $pixmap);

  local $MyTestImageBase::white = 'white';
  local $MyTestImageBase::black = 'black';
  MyTestImageBase::check_image ($image);
  MyTestImageBase::check_diamond ($image);
}

exit 0;
