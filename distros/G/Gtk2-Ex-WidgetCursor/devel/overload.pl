#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetCursor.
#
# Gtk2-Ex-WidgetCursor is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetCursor is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetCursor.  If not, see <http://www.gnu.org/licenses/>.


# use strict;
# use warnings;

{
  package MyOverloadWidget;
  use Carp;
  use overload
    'bool' => \&bool,
    '0+' => \&numize,
    '+' => \&add;
  sub new {
    my ($class) = @_;
    return bless {}, $class;
  }
  sub add {
    my ($x, $y, $swap) = @_;
    croak "I am not in the adding mood";
  }
  sub numize {
    my ($x) = @_;
    croak "I am not in the numizing mood";
  }
  sub bool {
    my ($x) = @_;
    croak "I am not in the boolean mood";
  }
}

my $obj = MyOverloadWidget->new;
print int($obj+0);
printf "%d\n", $obj;
print $obj+0;
