#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Gtk2;

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $r1 = Gtk2::Gdk::Rectangle->new (1,2,3,4);
  ### $r1
  my $r2 = $r1;
  undef $r1;
  ### r1: $r1 && $r1->values
  ### r2: $r2 && $r2->values
  exit 0;
}



my $pspec = Glib::ParamSpec->boxed
  ('myrect',
   'myrect',
   'Blurb.',
   'Gtk2::Gdk::Rectangle',
   Glib::G_PARAM_READWRITE);

my $rect = Gtk2::Gdk::Rectangle->new (1,2,3,4);
### rect values: $rect->values
my ($flag, $new) = $pspec->value_validate($rect);
# undef $rect;
### $flag
### $new
### new values: $new && $new->values
### rect values: $rect && $rect->values

exit 0;
