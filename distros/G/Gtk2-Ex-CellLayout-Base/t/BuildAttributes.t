#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-CellLayout-Base.
#
# Gtk2-Ex-CellLayout-Base is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-CellLayout-Base is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-CellLayout-Base.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
 SKIP: { eval 'use Test::NoWarnings; 1'
           or skip 'Test::NoWarnings not available', 1; }
}

require Gtk2::Ex::CellLayout::BuildAttributes;

{
  my $want_version = 5;
  is ($Gtk2::Ex::CellLayout::BuildAttributes::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::CellLayout::BuildAttributes->VERSION, $want_version,
      'VERSION class method');

  ok (eval { Gtk2::Ex::CellLayout::BuildAttributes->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::CellLayout::BuildAttributes->VERSION($check_version); 1 }, "VERSION class check $check_version");

}

exit 0;

