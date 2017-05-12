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
ok (! Test::Weaken::Gtk2::ignore_default_screen ($dummy_obj),
    'ignore_default_screen() when Gtk2 not loaded');

require Gtk2;
ok (! Test::Weaken::Gtk2::ignore_default_screen ($dummy_obj),
    'ignore_default_screen() when Gtk2->init not called');

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_init = Gtk2->init_check;

SKIP: {
  $have_init
    or skip 'due to no SCREEN available', 2;

  ok (! Test::Weaken::Gtk2::ignore_default_screen ($dummy_obj),
      'ignore_default_screen() dummy after Gtk2->init');

 SKIP: {
    Gtk2::Gdk::Screen->can('get_default')
        or skip 'due to no Gtk2::Gdk::Screen->get_default, per Gtk 2.0.x', 1;

    my $default_screen = Gtk2::Gdk::Screen->get_default;
    ok (Test::Weaken::Gtk2::ignore_default_screen ($default_screen),
        'ignore_default_screen() recognise default screen');
  }
}

exit 0;
