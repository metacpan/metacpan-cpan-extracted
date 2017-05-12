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

eval "use Test::Weaken 2.000; 1"
  or plan skip_all => "due to Test::Weaken 2.000 not available -- $@";
diag ("Test::Weaken version ", Test::Weaken->VERSION);

plan tests => 5;

require Glib::Ex::ConnectProperties;
require Glib;

#-----------------------------------------------------------------------------
{
  package Foo;
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
                    ];
}

#-----------------------------------------------------------------------------

# the "permanent" new() connp object is gc'ed when all its objects go
{
  my $leaks = Test::Weaken::leaks
    (sub {
       my $obj1 = Foo->new (myprop_one => 1, myprop_two => 1);
       my $obj2 = Foo->new (myprop_one => 0, myprop_two => 0);
       my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'myprop-one'],
                                                    [$obj2,'myprop-two']);
       return [ $obj1, $obj2, $conn ];
     });
  is ($leaks, undef, 'new() deep gc');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain($leaks) }; # explain in Test::More 0.82
  }
}

{
  my $leaks = Test::Weaken::leaks
    (sub {
       my $obj1 = Foo->new (myprop_one => 1, myprop_two => 1);
       my $obj2 = Foo->new (myprop_one => 0, myprop_two => 0);
       my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'myprop-one'],
                                                    [$obj2,'myprop-two']);
       undef $obj1;
       undef $obj2;
       return $conn;
     });
  is ($leaks, undef, 'new() deep gc -- with objects already gone');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain($leaks) }; # explain in Test::More 0.82
  }
}

{
  my $leaks = Test::Weaken::leaks
    (sub {
       my $obj1 = Foo->new (myprop_one => 1, myprop_two => 1);
       my $obj2 = Foo->new (myprop_one => 0, myprop_two => 0);
       my $conn = Glib::Ex::ConnectProperties->dynamic ([$obj1,'myprop-one'],
                                                        [$obj2,'myprop-two']);
       return [ $obj1, $obj2, $conn ];
     });
  is ($leaks, undef, 'dynamic() deep gc');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain($leaks) }; # explain in Test::More 0.82
  }
}

{
  my $leaks = Test::Weaken::leaks
    (sub {
       my $obj1 = Foo->new (myprop_one => 1, myprop_two => 1);
       my $obj2 = Foo->new (myprop_one => 0, myprop_two => 0);
       my $conn = Glib::Ex::ConnectProperties->dynamic ([$obj1,'myprop-one'],
                                                        [$obj2,'myprop-two']);
       undef $obj1;
       undef $obj2;
       return $conn;
     });
  is ($leaks, undef, 'dynamic() deep gc -- with objects already gone');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain($leaks) }; # explain in Test::More 0.82
  }
}

{
  my $obj1 = Foo->new (myprop_one => 1, myprop_two => 1);
  my $obj2 = Foo->new (myprop_one => 0, myprop_two => 0);
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         return Glib::Ex::ConnectProperties->dynamic ([$obj1,'myprop-one'],
                                                      [$obj2,'myprop-two']);
       },
       ignore => sub {
         my ($ref) = @_;
         return ($ref == $obj1 || $ref == $obj2);
       },
     });
  is ($leaks, undef, 'dynamic() deep gc -- with objects persisting');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain($leaks) }; # explain in Test::More 0.82
  }
}

exit 0;
