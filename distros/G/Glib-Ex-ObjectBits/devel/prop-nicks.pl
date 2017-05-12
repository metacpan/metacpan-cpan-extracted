#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Glib-Ex-ObjectBits.
#
# Glib-Ex-ObjectBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ObjectBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ObjectBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Gtk2;
use Package::Stash;

{
  foreach my $base ('Gtk2') {
    my $stash = Package::Stash->new($base);
    foreach my $part ($stash->list_all_package_symbols) {
      my $class = "${base}::${part}";
      $class =~ s/::$//;
      $class->can('list_properties') or next;
      print "$class\n";
      foreach my $pspec ($class->list_properties) {
        printf "  %-16s  \"%s\"\n", $pspec->get_name, $pspec->get_nick;
      }
    }
  }
  exit 0;
}
