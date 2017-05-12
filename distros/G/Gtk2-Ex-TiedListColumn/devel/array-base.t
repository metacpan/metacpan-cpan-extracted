#!/usr/bin/perl

# Copyright 2008 Kevin Ryde

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
use Gtk2::Ex::TiedListColumn;

use Test::More tests => 9;
use Gtk2;

diag ("Perl-Gtk2 version ",Gtk2->VERSION);
diag ("Perl-Glib version ",Glib->VERSION);
diag ("Compiled against Glib version ",
      Glib::MAJOR_VERSION(), ".",
      Glib::MINOR_VERSION(), ".",
      Glib::MICRO_VERSION(), ".");
diag ("Running on       Glib version ",
      Glib::major_version(), ".",
      Glib::minor_version(), ".",
      Glib::micro_version(), ".");
diag ("Compiled against Gtk version ",
      Gtk2::MAJOR_VERSION(), ".",
      Gtk2::MINOR_VERSION(), ".",
      Gtk2::MICRO_VERSION(), ".");
diag ("Running on       Gtk version ",
      Gtk2::major_version(), ".",
      Gtk2::minor_version(), ".",
      Gtk2::micro_version(), ".");


$[ = 6;

my $store = Gtk2::ListStore->new ('Glib::String');
$store->set ($store->insert(0), 0=>'zero');
$store->set ($store->insert(1), 0=>'one');
$store->set ($store->insert(2), 0=>'two');
my @a;
tie @a, 'Gtk2::Ex::TiedListColumn', $store;

# FETCHSIZE
is (scalar @a, 3);
my $last = $#a; # with this file's $[, not Test::More
is ($last, 8);

# FETCH
is ($a[6], 'zero');
is ($a[7], 'one');
is ($a[8], 'two');
is ($a[9], undef);

# STORE
$a[7] = 'xxx';
is ($a[7], 'xxx');


# These reach the methods $[ based ...
#
# # EXISTS
# delete $a[7];
# ok (exists $a[6]);
# ok (! exists $a[10]);
# 
# # DELETE
# delete $a[7];
# is ($a[7], undef);
# is ($a[8], 'two');
# 
# # SPLICE
# splice @a, 6,1, 'hello';
# is ($a[6], 'hello');


exit 0;
