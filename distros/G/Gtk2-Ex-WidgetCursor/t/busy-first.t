#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetCursor.
#
# Gtk2-Ex-WidgetCursor is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetCursor is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetCursor.  If not, see <http://www.gnu.org/licenses/>.


# specific test of go busy when no widgets, exercising a workaround for
# Gtk2-Perl 1.181

use strict;
use warnings;
use Gtk2::Ex::WidgetCursor;
use Test::More tests => 1;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

SKIP: {
  require Gtk2;
  Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
  if (! Gtk2->init_check) { skip 'due to no DISPLAY available', 1; }

  Gtk2::Ex::WidgetCursor->busy;
  ok (1);
}

exit 0;
