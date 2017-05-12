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
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2;
use Test::Without::Gtk2Things;

{
  Gtk2::MenuItem->new;
  $,='  ';
  print @Gtk2::MenuItem::ISA,"\n";
  foreach my $class (@Gtk2::MenuItem::ISA) {
    print $class->can('get_label'),"\n";
  }

  Test::Without::Gtk2Things::_without_methods ('Gtk2::MenuItem', "get_label", "set_label");
  if (Gtk2::MenuItem->can('get_label')) {
    die 'Oops, Gtk2::MenuItem still can("get_label")';
  }

  exit 0;
}

