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
use Gtk2::Ex::TreeModelBits
  'all_column_types', 'column_contents', 'remove_matching_rows', 'iter_prev';
use Test::More tests => 4;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $store = Gtk2::ListStore->new ('Glib::String', 'Glib::Int');

#------------------------------------------------------------------------------
is_deeply ([ all_column_types ($store) ],
           [ 'Glib::String', 'Glib::Int' ],
           'all_column_types');

#------------------------------------------------------------------------------
# column_contents()
is_deeply ([ column_contents ($store, 1) ], [], 'column_contents()');

#------------------------------------------------------------------------------
# remove_matching_rows()

remove_matching_rows ($store, sub { return 1; });
is ($store->iter_n_children(undef), 0, 'remove_matching_rows()');

#------------------------------------------------------------------------------
# iter_prev()

$store->insert(0);
is (iter_prev ($store, $store->get_iter_first), undef, 'iter_prev()');

exit 0;
