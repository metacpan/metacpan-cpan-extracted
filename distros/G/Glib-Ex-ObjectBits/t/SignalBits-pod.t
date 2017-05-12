#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Glib-Ex-ObjectBits.
#
# Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ObjectBits.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Gtk2 }
    or plan skip_all => "due to Gtk2 not available -- $@";
  Gtk2->init_check
    or plan skip_all => 'due to no DISPLAY available';
}
plan tests => 1;

{
  package SignalBitsPodExample;
  use Glib::Ex::SignalBits;

  use Glib::Object::Subclass
    'Gtk2::Widget',
    signals => {
      'make-title' => {
        param_types   => ['Glib::Int'],
        return_type   => 'Glib::String',
        flags         => ['run-last'],
        class_closure => \&my_default_make_title,
        accumulator   => \&Glib::Ex::SignalBits::accumulator_first_defined,
      },
    };

  sub my_default_make_title {
    return 'hello';
  }
}

{
  my $widget = SignalBitsPodExample->new;
  is ($widget->signal_emit ('make-title', 123),
      'hello');
}

exit 0;
