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

plan tests => 17;

use_ok ('Image::Base::Gtk2::Gdk::Window');
diag "Image::Base version ", Image::Base->VERSION;


#------------------------------------------------------------------------------
# VERSION

my $want_version = 11;
is ($Image::Base::Gtk2::Gdk::Window::VERSION,
    $want_version, 'VERSION variable');
is (Image::Base::Gtk2::Gdk::Window->VERSION,
    $want_version, 'VERSION class method');

ok (eval { Image::Base::Gtk2::Gdk::Window->VERSION($want_version); 1 },
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { Image::Base::Gtk2::Gdk::Window->VERSION($check_version); 1 },
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# new()

{
  my $rootwin = Gtk2::Gdk->get_default_root_window;
  my $image = Image::Base::Gtk2::Gdk::Window->new
    (-window => $rootwin);
  isa_ok ($image, 'Image::Base');
  isa_ok ($image, 'Image::Base::Gtk2::Gdk::Drawable');
  isa_ok ($image, 'Image::Base::Gtk2::Gdk::Window');

  is ($image->VERSION,  $want_version, 'VERSION object method');
  ok (eval { $image->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $image->VERSION($check_version); 1 },
      "VERSION object check $check_version");

  is ($image->get('-drawable'), $rootwin, 'get() -drawable');
  is ($image->get('-window'),   $rootwin, 'get() -window');
  is ($image->get('-file'), undef, 'get() -file');
  cmp_ok ($image->get('-depth'), '>', 0, 'get() -depth');

  is ($image->get('-screen'),   $rootwin->get_screen,   'get() -screen');
  is ($image->get('-colormap'), $rootwin->get_colormap, 'get() -colormap');
}

exit 0;
