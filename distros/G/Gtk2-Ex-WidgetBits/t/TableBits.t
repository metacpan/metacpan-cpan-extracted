#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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


use strict;
use warnings;
use Test::More tests => 7;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::TableBits;

#-----------------------------------------------------------------------------
# VERSION

{
  my $want_version = 48;
  is ($Gtk2::Ex::TableBits::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::TableBits->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Gtk2::Ex::TableBits->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::TableBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

require Gtk2;
MyTestHelpers::glib_gtk_versions();


#-----------------------------------------------------------------------------
# update_attach()

{
  my $table = Gtk2::Table->new (10, 20);
  my $table2 = Gtk2::Table->new (10, 20);
  my $child = Gtk2::Label->new ('hello');

  Gtk2::Ex::TableBits::update_attach
      ($table, $child, 0,3, 4,5,
       ['fill','shrink','expand'], [], 0,0);
  is ($table->child_get_property($child,'bottom-attach'),
      5);

  Gtk2::Ex::TableBits::update_attach
      ($table, $child, 0,3, 4,6,
       ['fill','shrink','expand'], [], 0,0);
  is ($table->child_get_property($child,'bottom-attach'),
      6);

  Gtk2::Ex::TableBits::update_attach
      ($table2, $child, 0,3, 4,6,
       ['fill','shrink','expand'], [], 0,0);
  is ($child->get_parent,
      $table2);
}


#-----------------------------------------------------------------------------
exit 0;
