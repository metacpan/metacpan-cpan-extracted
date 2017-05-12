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

{
  package Foo;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      properties => [Glib::ParamSpec->unichar
                     ('mychar',
                      'mychar',
                      'Blurb.',
                      'x',
                      Glib::G_PARAM_READWRITE)
                    ];

  sub GET_PROPERTY {
    my ($self, $pspec) = @_;
    return ($self->{'mychar'} || 65);
  }

  sub SET_PROPERTY {
    my ($self, $pspec, $newval) = @_;
    $self->{'mychar'} = $newval;
  }
}

use strict;
use warnings;
use Glib::Ex::ConnectProperties;
use Data::Dumper;

my $foo = Foo->new;
my $pspec = $foo->find_property ('mychar');
{ my $default = $pspec->get_default_value;
  print Dumper(\$default);
}
{ my $value = $foo->get('mychar');
  print Dumper(\$value);
}
$foo->set('mychar',70);
{ my $value = $foo->get('mychar');
  print Dumper(\$value);
}

exit 0;
