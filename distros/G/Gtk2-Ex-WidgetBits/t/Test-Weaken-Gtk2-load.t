#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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

use Test::Weaken::Gtk2 'contents_container';
contents_container([]);
Test::Weaken::Gtk2::contents_submenu([]);
Test::Weaken::Gtk2::contents_cell_renderers([]);
# Test::Weaken::Gtk2::destructor_destroy([]);
# Test::Weaken::Gtk2::destructor_destroy_and_iterate([]);
Test::Weaken::Gtk2::ignore_default_display([]);

use Test::More tests => 1;
ok (1, 'Test::Weaken::Gtk2 load as first thing');
exit 0;
