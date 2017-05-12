#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Gtk2-Ex-ComboBoxBits.
#
# Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ComboBoxBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Gtk2::Ex::ComboBoxBits qw(get_active_path
                              set_active_path
                              set_active_text
                              find_text_iter);

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';

plan tests => 3;

my $combobox = Gtk2::ComboBox->new;
is (get_active_path($combobox), undef);
is (find_text_iter($combobox, 'nosuchentry'), undef);

set_active_path($combobox,Gtk2::TreePath->new_from_indices(0,0));
set_active_text($combobox,'nosuchentry');
ok(1);

exit 0;
