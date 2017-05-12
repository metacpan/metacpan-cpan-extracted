#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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

# uncomment this to run the ### lines
#use Smart::Comments;

BEGIN {
  eval { require Gtk2 }
    or plan skip_all => "due to Gtk2 module not available -- $@";
  Gtk2->init_check
    or plan skip_all => "due to no DISPLAY";
  Gtk2::Gdk::Screen->can('get_default')
      or plan skip_all => "due to no Gtk2::Gdk::Screen (probably gtk pre 2.2";
}

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

my $screen = Gtk2::Gdk::Screen->get_default;

#-----------------------------------------------------------------------------
# windowed DrawingArea screen

{
  my $foo_width     = Foo->new;
  my $foo_height    = Foo->new;
  my $foo_width_mm  = Foo->new;
  my $foo_height_mm = Foo->new;
  Glib::Ex::ConnectProperties->new ([$screen,'screen-size#width'],
                                    [$foo_width,'mystring']);
  Glib::Ex::ConnectProperties->new ([$screen,'screen-size#height'],
                                    [$foo_height,'mystring']);
  Glib::Ex::ConnectProperties->new ([$screen,'screen-size#width-mm'],
                                    [$foo_width_mm,'mystring']);
  Glib::Ex::ConnectProperties->new ([$screen,'screen-size#height-mm'],
                                    [$foo_height_mm,'mystring']);
  is ($foo_width->get('mystring'), $screen->get_width);
  is ($foo_height->get('mystring'), $screen->get_height);
  is ($foo_width_mm->get('mystring'), $screen->get_width_mm);
  is ($foo_height_mm->get('mystring'), $screen->get_height_mm);
}

exit 0;
