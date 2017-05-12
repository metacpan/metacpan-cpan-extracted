#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-NumAxis.
#
# Gtk2-Ex-NumAxis is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-NumAxis is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-NumAxis.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use POSIX;

BEGIN {
  # $ENV{'LANG'} = 'ja_JP.utf8';
  # $ENV{'LC_ALL'} = 'ja_JP.utf8';
  # delete $ENV{'LANGUAGE'};

  $ENV{'LANG'} = 'de_DE';
  $ENV{'LC_ALL'} = 'de_DE';
  $ENV{'LANGUAGE'} = 'de';

  require POSIX;
  print "setlocale to ",POSIX::setlocale(POSIX::LC_ALL(),""),"\n";
}

use Gtk2::Ex::NumAxis;

{
  foreach my $pname ('inverted', 'orientation') {
    my $pspec = Gtk2::Ex::NumAxis->find_property($pname);
    my $nick = $pspec->get_nick;
    print "$pname   name=\"$nick\"\n";
  }
  exit 0;
}
