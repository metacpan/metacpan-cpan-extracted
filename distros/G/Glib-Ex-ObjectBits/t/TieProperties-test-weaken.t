#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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

use strict;
use warnings;
use Glib::Ex::TieProperties;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# Test::Weaken 2.000 for leaks(), but 3.002 preferred as descends into the
# tied object ...
eval "use Test::Weaken 2.000; 1"
  or plan skip_all => "due to Test::Weaken 2.000 not available -- $@";

plan tests => 1;

diag ("Test::Weaken version ", Test::Weaken->VERSION);
require Glib;
MyTestHelpers::glib_gtk_versions();


#-----------------------------------------------------------------------------

{
  package MyObject;
  use strict;
  use warnings;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      properties => [Glib::ParamSpec->boolean
                     ('myprop-one',
                      'myprop-one',
                      'Blurb.',
                      0,
                      Glib::G_PARAM_READWRITE),

                     Glib::ParamSpec->boolean
                     ('myprop-two',
                      'myprop-two',
                      'Blurb.',
                      0,
                      Glib::G_PARAM_READWRITE),

                     Glib::ParamSpec->double
                     ('writeonly-double',
                      'writeonly-double',
                      'Blurb.',
                      -1000, 1000, 111,
                      ['writable']),

                     Glib::ParamSpec->float
                     ('readonly-float',
                      'readonly-float',
                      'Blurb.',
                      -2000, 2000, 222,
                      ['readable']),
                    ];
}

#-----------------------------------------------------------------------------
# new()

{
  # Test::Weaken 3.002 descends into the tie itself, when ready to require
  # that
  #
  my $leaks = Test::Weaken::leaks
    (sub {
       my $obj = MyObject->new;
       my $h = Glib::Ex::TieProperties->new($obj);
       return [ $h, $obj ];
     });
  is ($leaks, undef, 'deep garbage collection');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain $leaks;
  }
}

exit 0;
