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
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Glib::Ex::ConnectProperties;

eval { require Gtk2 }
  or plan skip_all => "due to Gtk2 module not available -- $@";
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
                    ];
}

#------------------------------------------------------------------------------
# empty / not-empty

{
  my $foo = MyClass->new;
  my $bar = MyClass->new;

  my $model = Gtk2::TreeStore->new ('Glib::String');
  Glib::Ex::ConnectProperties->new
      ([$model, 'model-rows#empty'],
       [$foo,   'mybool']);
  Glib::Ex::ConnectProperties->new
      ([$model, 'model-rows#not-empty'],
       [$bar,   'mybool']);

  ok (  $foo->get('mybool'), 'empty - initial');
  ok (! $bar->get('mybool'), 'not-empty - initial');

  $model->insert (undef, 0); # row 0
  ok (! $foo->get('mybool'), 'empty - one');
  ok (  $bar->get('mybool'), 'not-empty - one');

  $model->insert ($model->iter_nth_child(undef,0),  # sub-row 0:0
                  0);
  $model->insert (undef, 1); # row 1
  ok (! $foo->get('mybool'), 'empty - two');
  ok (  $bar->get('mybool'), 'not-empty - two');

  $model->remove ($model->iter_nth_child(undef,1));  # row 1
  ok (! $foo->get('mybool'), 'empty - removed two');
  ok (  $bar->get('mybool'), 'not-empty - removed two');

  $model->remove ($model->iter_nth_child(undef,0));  # row 0
  ok (  $foo->get('mybool'), 'empty - removed one');
  ok (! $bar->get('mybool'), 'not-empty - removed one');
}

exit 0;
