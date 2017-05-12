#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Glib::Ex::ConnectProperties;

eval { require Gtk2 }
  or plan skip_all => "due to Gtk2 module not available -- $@";
MyTestHelpers::glib_gtk_versions();

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => "due to no DISPLAY";

plan tests => 18;


{
  package Foo;
  use strict;
  use warnings;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      properties => [ Glib::ParamSpec->string
                      ('mystring',
                       'mystring',
                       'Blurb.',
                       '', # default
                       Glib::G_PARAM_READWRITE),

                      Glib::ParamSpec->object
                      ('myobj',
                       'myobj',
                       'Blurb.',
                       'Glib::Object',
                       Glib::G_PARAM_READWRITE),

                      Glib::ParamSpec->boolean
                      ('mybool',
                       'mybool',
                       'Blurb.',
                       0, # default
                       Glib::G_PARAM_READWRITE),
                    ];
}

#------------------------------------------------------------------------------
# direction

{
  my $foo = Foo->new (mystring => 'initial mystring');

  my $label = Gtk2::Label->new;
  Glib::Ex::ConnectProperties->new
      ([$label, 'widget#direction'],
       [$foo,   'mystring']);
  is ($label->get_direction, $foo->get('mystring'));

  $label->set_direction ('none');
  is ($label->get_direction, $foo->get('mystring'));

  $label->set_direction ('ltr');
  is ($label->get_direction, $foo->get('mystring'));

  $label->set_direction ('rtl');
  is ($label->get_direction, $foo->get('mystring'));

  $foo->set (mystring => 'ltr');
  is ($label->get_direction, $foo->get('mystring'));

  $foo->set (mystring => 'rtl');
  is ($label->get_direction, $foo->get('mystring'));
}

#------------------------------------------------------------------------------
# screen

SKIP: {
  Gtk2::Widget->can('get_screen')
      or skip 'no get_screen(), per Gtk 2.0.x', 1;

  my $foo = Foo->new;

  my $label = Gtk2::Label->new;
  Glib::Ex::ConnectProperties->new
      ([$label, 'widget#screen'],
       [$foo,   'myobj']);
  is ($label->get_screen, $foo->get('myobj'));
}

#------------------------------------------------------------------------------
# has-screen

SKIP: {
  Gtk2::Widget->can('has_screen')
      or skip 'no has_screen(), per Gtk 2.0.x', 5;

  my $foo = Foo->new (mystring => 'initial mystring');

  my $label = Gtk2::Label->new;
  Glib::Ex::ConnectProperties->new
      ([$label, 'widget#has-screen'],
       [$foo,   'mybool']);
  is (!! $label->has_screen, !! $foo->get('mybool'),
      'initial label/foo has-screen');

  my $toplevel = Gtk2::Window->new('toplevel');
  $toplevel->add($label);
  ok ($label->has_screen, 'label has_screen true');
  ok ($foo->get('mybool'), 'foo has-screen true');

  $toplevel->remove($label);
  ok (! $label->has_screen, 'label has_screen false');
  ok (! $foo->get('mybool'), 'foo has-screen false');
  $toplevel->destroy;
}

#------------------------------------------------------------------------------
# state

{
  my $foo = Foo->new (mystring => 'initial mystring');

  my $label = Gtk2::Label->new;
  Glib::Ex::ConnectProperties->new
      ([$label, 'widget#state'],
       [$foo,   'mystring']);
  is ($label->state, $foo->get('mystring'));

  $label->set_state ('selected');
  is ($label->state, $foo->get('mystring'));

  $label->set_state ('normal');
  is ($label->state, $foo->get('mystring'));

  $label->set_state ('active');
  is ($label->state, $foo->get('mystring'));

  $foo->set (mystring => 'prelight');
  is ($label->state, $foo->get('mystring'));

  $foo->set (mystring => 'selected');
  is ($label->state, $foo->get('mystring'));
}

exit 0;
