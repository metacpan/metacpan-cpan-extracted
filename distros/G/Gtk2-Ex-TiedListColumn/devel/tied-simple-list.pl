#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TiedListColumn.
#
# Gtk2-Ex-TiedListColumn is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-TiedListColumn is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TiedListColumn.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Gtk2;

my $store = Gtk2::ListStore->new ('Glib::Int');
$store->insert_with_values (0, 0=>123);
$store->insert_with_values (1, 0=>456);
$store->insert_with_values (2, 0=>789);


{
  require Gtk2::Ex::Simple::TiedList;
  my @s;
  tie @s, 'Gtk2::Ex::Simple::TiedList', $store;

  print "s len $#s\n";
  print Dumper(\@s);
  foreach my $i (0 .. $#s) {
    print $s[$i],"\n";
    print Dumper($s[$i]);
  }
  exit 0;
}
{
  require Gtk2::Ex::TiedListColumn;
  my @a;
  tie @a, 'Gtk2::Ex::TiedListColumn', $store;
  print $a[0],"\n";
  print $a[1],"\n";
  print $a[-1],"\n";

  $a[-1] = 777;
  if (exists $a[-1]) { print "yes\n"; }
  delete $a[1];
  print "$#a $a[0] $a[1] $a[2]\n";

  use Data::Dumper;
  my @b = (123, 456, 789);
  delete $b[0];
  print Dumper(\@b);

  {
    my @c = ();
    my @d = pop @c;
    print Dumper(\@d);
  }

  $#a = 1;
  my @d = splice @a;
  print Dumper(\@d);
}

