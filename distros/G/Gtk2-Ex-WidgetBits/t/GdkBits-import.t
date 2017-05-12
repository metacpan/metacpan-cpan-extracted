#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Gtk2::Ex::GdkBits qw(window_get_root_position
                         window_clear_region);

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to Gtk2->init_check() unsuccessful';

plan tests => 1;

{
  my $root = Gtk2::Gdk->get_default_root_window;
  is_deeply ([ window_get_root_position ($root) ],
             [ 0, 0 ],
             'window_get_root_position() on root window');
}

{
  my $root = Gtk2::Gdk->get_default_root_window;
  my $region = Gtk2::Gdk::Region->new;
  window_clear_region ($root, $region);

  $region->union_with_rect (Gtk2::Gdk::Rectangle->new (0,0, 10, 10));
  window_clear_region ($root, $region);
}

exit 0;
