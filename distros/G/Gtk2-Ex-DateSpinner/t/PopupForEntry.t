#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2013 Kevin Ryde

# This file is part of Gtk2-Ex-DateSpinner.
#
# Gtk2-Ex-DateSpinner is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-DateSpinner is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-DateSpinner.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Test::More tests => 4;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::DateSpinner::PopupForEntry;

{
  my $want_version = 10;
  is ($Gtk2::Ex::DateSpinner::PopupForEntry::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::DateSpinner::PopupForEntry->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { Gtk2::Ex::DateSpinner::PopupForEntry->VERSION($want_version); 1 },
      "VERSION class check $want_version");

  my $check_version = $want_version + 1000;
  ok (! eval{Gtk2::Ex::DateSpinner::PopupForEntry->VERSION($check_version); 1},
      "VERSION class check $check_version");
}

exit 0;
