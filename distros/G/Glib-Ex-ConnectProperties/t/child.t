#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Glib::Ex::ConnectProperties;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

eval { require Gtk2 }
  or plan skip_all => "due to Gtk2 module not available -- $@";
MyTestHelpers::glib_gtk_versions();

Gtk2::Container->can('find_child_property')
  or plan skip_all => "due to no Gtk2::Container find_child_property()";

plan tests => 4;


{
  package Foo;
  use strict;
  use warnings;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      properties => [Glib::ParamSpec->string
                     ('mystring',
                      'mystring',
                      'Blurb.',
                      '', # default
                      Glib::G_PARAM_READWRITE),
                    ];
}

{
  my $foo = Foo->new (mystring => 'initial mystring');

  my $drawing = Gtk2::DrawingArea->new;
  my $layout = Gtk2::Layout->new;
  $layout->put ($drawing, 2, 3);

  is ($foo->get('mystring'), 'initial mystring');
  Glib::Ex::ConnectProperties->new
      ([$drawing, 'child#x'],
       [$foo, 'mystring']);
  is ($foo->get('mystring'), 2);

  $layout->move ($drawing, 4, 5);
  is ($foo->get('mystring'), 4);

  $foo->set (mystring => 6);
  is ($layout->child_get_property($drawing,'x'), 6);

  $layout->remove ($drawing);
  $foo->set (mystring => 99);
}

exit 0;
