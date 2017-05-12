#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

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
use Test::More tests => 104;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::TreeModel::ImplBits;

{
  my $want_version = 48;
  is ($Gtk2::Ex::TreeModel::ImplBits::VERSION, $want_version, 'VERSION variable');
  is (Gtk2::Ex::TreeModel::ImplBits->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Gtk2::Ex::TreeModel::ImplBits->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::TreeModel::ImplBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}


{
  my $obj = {};
  foreach (1 .. 50) {
    my $old = $obj->{'stamp'};
    Gtk2::Ex::TreeModel::ImplBits::random_stamp($obj);
    cmp_ok ($obj->{'stamp'}, '>=', 1);
    isnt ($obj->{'stamp'}, $old, 'random_stamp() different from old');
  }
}

exit 0;
