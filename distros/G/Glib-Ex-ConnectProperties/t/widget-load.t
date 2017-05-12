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

eval { require Module::Util }
  or plan skip_all => "due to Module::Util not available -- $@";
{
 my $find = Module::Util::find_installed('Gtk2');
  diag 'find Gtk2: ',$find;
  $find
    or plan skip_all => 'due to Gtk2 module not available';
}

plan tests => 1;

{
  package Foo;
  use strict;
  use warnings;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      signals => { direction_changed => { },
                 },
      properties => [Glib::ParamSpec->string
                     ('mystring',
                      'mystring',
                      'Blurb.',
                      '', # default
                      Glib::G_PARAM_READWRITE),
                    ];
  sub get_direction {
    my ($self) = @_;
    return $self->{'direction'};
  }
  sub set_direction {
    my ($self, $dir) = @_;
    $self->{'direction'} = $dir;
  }
}

#------------------------------------------------------------------------------
# check widget.pm loads without Gtk2 yet loaded

{
  my $foo = Foo->new (mystring => 'initial mystring');
  my $bar = Foo->new (mystring => 'initial mystring');

  require Glib::Ex::ConnectProperties;
  Glib::Ex::ConnectProperties->new
      ([$foo, 'widget#direction'],
       [$bar, 'mystring']);
  ok(1);
}

exit 0;
