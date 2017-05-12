#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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

# uncomment this to run the ### lines
#use Smart::Comments;

require Glib::Ex::ConnectProperties;

eval { require Gtk2 }
  or plan skip_all => "due to Gtk2 module not available -- $@";
Gtk2->init_check
  or plan skip_all => "due to no DISPLAY";
MyTestHelpers::glib_gtk_versions();

plan tests => 10;


{
  package MyClass;
  use strict;
  use warnings;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      properties => [ Glib::ParamSpec->boolean
                      ('mybool',
                       'mybool',
                       'Blurb.',
                       0, # default
                       Glib::G_PARAM_READWRITE),

                      Glib::ParamSpec->int
                      ('myint',
                       'myint',
                       'Blurb.',
                       0, 9999,  # min, max
                       0,        # default
                       Glib::G_PARAM_READWRITE),
                    ];
}

#------------------------------------------------------------------------------
# empty / not-empty / char-count

{
  my $foo = MyClass->new;
  my $bar = MyClass->new;

  my $textbuf = Gtk2::TextBuffer->new;

  Glib::Ex::ConnectProperties->new
      ([$textbuf, 'textbuffer#empty'],
       [$foo, 'mybool']);
  Glib::Ex::ConnectProperties->new
      ([$textbuf, 'textbuffer#char-count'],
       [$foo, 'myint']);
  Glib::Ex::ConnectProperties->new
      ([$textbuf, 'textbuffer#not-empty'],
       [$bar, 'mybool']);

  ok (  $foo->get('mybool'), 'empty - initial');
  ok (! $bar->get('mybool'), 'not-empty - initial');
  ok (! $bar->get('mybool'), 'not-empty - initial');
  is ($foo->get('myint'), 0, 'count - initial');

  $textbuf->set_text ('abc');

  ok (! $foo->get('mybool'), 'empty - abc');
  ok (  $bar->get('mybool'), 'not-empty - abc');
  is ($foo->get('myint'), 3, 'count - abc');

  $textbuf->set_text ('');

  ok (  $foo->get('mybool'), 'empty - cleared');
  ok (! $bar->get('mybool'), 'not-empty - cleared');
  is ($foo->get('myint'), 0, 'count - cleared');
}

#------------------------------------------------------------------------------
exit 0;
