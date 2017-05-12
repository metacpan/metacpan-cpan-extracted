#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Clock.
#
# Gtk2-Ex-Clock is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Clock is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Clock.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;
use Gtk2;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => "due to no DISPLAY";

plan tests => 2;
MyTestHelpers::glib_gtk_versions();

require Gtk2::Ex::Clock;

#-----------------------------------------------------------------------------
# initial size_request()

# no circular reference between the clock and the timer callback it
# installs
{
  my $empty_label = Gtk2::Label->new;
  my $empty_req = $empty_label->size_request;

  my $clock = Gtk2::Ex::Clock->new;
  my $clock_req = $clock->size_request;

  cmp_ok ($clock_req->width, '>', $empty_req->width,
          'initially wider than an empty label');
  cmp_ok ($clock_req->height, '>', 1,
          'initially taller than an empty label');
}

exit 0;
