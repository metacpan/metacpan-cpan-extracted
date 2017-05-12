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

use 5.008;
use strict;
use warnings;

use Glib;

{
  package MyClass;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
        properties => [ Glib::ParamSpec->int
                        ('myprop',
                         'myprop',
                         'Blurb',
                         0, 100, 50,
                         Glib::G_PARAM_READWRITE) ];
}

{
  my $obj = MyClass->new;
  my $id = $obj->signal_connect (nosuchsignal => sub {});
  print "nosuchsignal id $id\n";
  exit 0;
}

{
  my $obj = MyClass->new;
  my $id = 0;
  if ($obj->signal_handler_is_connected ($id)) {
    print "id==0 connected\n";
  } else {
    print "id==0 not connected\n";
  }
  exit 0;
}


exit 0;
