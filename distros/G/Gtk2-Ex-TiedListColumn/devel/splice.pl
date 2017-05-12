#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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

{
  # scalar return first last of list
  my @array = (0,1,2,3,4,5);
  my $ret = splice @array, 2,undef, 'x','y';
  print $ret,"\n";
  print @array,"\n";
  exit 0;
}

{
  # scalar return first last of list
  my @array = (0,1,2,3,4,5);
  my $ret = splice @array, 2,2;
  print $ret,"\n";
  print @array,"\n";
  exit 0;
}
