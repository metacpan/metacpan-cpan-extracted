#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

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

use 5.008;
use strict;
use warnings;
use Test::More tests => 8;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Glib::Ex::ObjectBits 'set_property_maybe';

{
  my $want_version = 16;
  is ($Glib::Ex::ObjectBits::VERSION, $want_version, 'VERSION variable');
  is (Glib::Ex::ObjectBits->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Glib::Ex::ObjectBits->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Glib::Ex::ObjectBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
# set_property_maybe()

{
  package MyClass;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
        properties => [ Glib::ParamSpec->int
                        ('myprop',
                         'myprop',
                         'Blurb',
                         0,    # min
                         100,  # max
                         50,   # default
                         Glib::G_PARAM_READWRITE) ];
}

{
  my $foo = MyClass->new;
  Glib::Ex::ObjectBits::set_property_maybe ($foo,
                                            nosuch => 99,
                                            another_nosuch => 99);

  Glib::Ex::ObjectBits::set_property_maybe ($foo,
                                            myprop => 33);
  is ($foo->get('myprop'), 33);

  Glib::Ex::ObjectBits::set_property_maybe ($foo,
                                            nosuch => 99,
                                            myprop => 44);
  is ($foo->get('myprop'), 44);


  $foo->Glib::Ex::ObjectBits::set_property_maybe (myprop => 55);
  is ($foo->get('myprop'), 55);

  set_property_maybe ($foo, myprop => 66);
  is ($foo->get('myprop'), 66);
}

exit 0;
