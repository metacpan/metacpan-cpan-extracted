#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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

require Test::Weaken::Gtk2;

plan tests => 4;

my $dummy_obj = [];
ok (! Test::Weaken::Gtk2::ignore_default_root_window ($dummy_obj),
    'ignore_default_root_window() when Gtk2 not loaded');

require Gtk2;
ok (! Test::Weaken::Gtk2::ignore_default_root_window ($dummy_obj),
    'ignore_default_root_window() when Gtk2->init not called');

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_init = Gtk2->init_check;

SKIP: {
  $have_init
    or skip 'due to Gtk2->init_check() unsuccessful', 2;

  ok (! Test::Weaken::Gtk2::ignore_default_root_window ($dummy_obj),
      'ignore_default_root_window() dummy after Gtk2->init');

  my $default_root_window = Gtk2::Gdk->get_default_root_window;
  ok (Test::Weaken::Gtk2::ignore_default_root_window ($default_root_window),
      'ignore_default_root_window() recognise default root window');
}

exit 0;
