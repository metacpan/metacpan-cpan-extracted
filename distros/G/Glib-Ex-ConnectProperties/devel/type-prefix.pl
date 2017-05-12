#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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

# uncomment this to run the ### lines
use Smart::Comments;

{
  package Foo::Bar;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      properties => [Glib::ParamSpec->int
                     ('myprop',
                      'myprop',
                      'Blurb.',
                      0, 999, 0,
                      Glib::G_PARAM_READWRITE)
                    ];
  sub SET_PROPERTY {
    my ($self, $pspec, $value) = @_;
    ### Foo-Bar SET_PROPERTY()
  }
}

{
  my $pspec_xy;
  BEGIN {
    $pspec_xy = Glib::ParamSpec->int
      ('x/#$y',
       'xx/yy',
       'Blurb.',
       0, 999, 0,
       Glib::G_PARAM_READWRITE);
  }
  ### $pspec_xy
  ### name: $pspec_xy->get_name
  ### nick: $pspec_xy->get_nick

  package Quux;
  use Glib;
  use Glib::Object::Subclass
    'Foo::Bar',
      properties => [Glib::ParamSpec->int
                     ('myprop',
                      'myprop',
                      'Blurb.',
                      0, 999, 0,
                      Glib::G_PARAM_READWRITE),
                     Glib::ParamSpec->int
                     ('qint',
                      'qint',
                      'Blurb.',
                      0, 999, 0,
                      Glib::G_PARAM_READWRITE),
                     $pspec_xy,
                    ];
  sub SET_PROPERTY {
    my ($self, $pspec, $value) = @_;
    ### Quux SET_PROPERTY()
  }
}

my $f = Quux->new;
$f->get_property ('myprop');
print $f->get_property ('Foo__Bar::myprop'),"\n";

$f->set_property ('Foo__Bar::myprop', 123);
print $f->get_property ('myprop'),"\n";

$f->set_property ('Foo__Bar::myprop', 123);
$f->set_property ('Quux::myprop', 123);

### p xy: $f->find_property('x###y')
### p xy: $f->find_property('x_y')
print "xy ", $f->get_property('x#y'),"\n";
print "xy ", $f->get_property('xx/yy'),"\n";

### qint
$f->set_property ('qint', 123);
$f->set_property ('Quux::qint', 123);
$f->set_property ('Foo__Bar::qint', 123);




exit 0;
