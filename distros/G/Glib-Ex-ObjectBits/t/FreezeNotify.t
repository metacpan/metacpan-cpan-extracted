#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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
use Glib::Ex::FreezeNotify;
use Test::More tests => 23;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Glib;
MyTestHelpers::glib_gtk_versions();


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

                       Glib::ParamSpec->int
                       ('myprop-integer',
                        'myprop-integer',
                        'Blurb.',
                        0, 100, 0,
                        Glib::G_PARAM_READWRITE),
                      ];
}

# version number
{
  my $want_version = 16;
  is ($Glib::Ex::FreezeNotify::VERSION, $want_version,
      'VERSION variable');
  is (Glib::Ex::FreezeNotify->VERSION, $want_version,
      'VERSION class method');
  ok (eval { Glib::Ex::FreezeNotify->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  ok (! eval { Glib::Ex::FreezeNotify->VERSION($want_version + 1000); 1 },
      "VERSION class check " . ($want_version + 1000));

  my $obj = Foo->new;
  my $freezer = Glib::Ex::FreezeNotify->new ($obj);

  is ($freezer->VERSION, $want_version, 'VERSION object method');
  ok (eval { $freezer->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $freezer->VERSION($want_version + 1000); 1 },
      "VERSION object check " . ($want_version + 1000));
}

{
  my $obj = Foo->new;
  my $notified = 0;
  $obj->signal_connect (notify => sub { $notified = 1; });

  {
    my $freezer = Glib::Ex::FreezeNotify->new ($obj);
    ok (! $notified);
    $obj->set (myprop_one => 1);
    $obj->set (myprop_two => 1);
    ok (! $notified, 'freezer alive, no notify yet');
  }
  ok ($notified, 'notify goes out after freezer dies');
}

# notify goes out on two objects when $freezer dies
{
  my $obj1 = Foo->new;
  my $obj2 = Foo->new;
  my $notified1 = 0;
  my $notified2 = 0;
  $obj1->signal_connect (notify => sub { $notified1 = 1; });
  $obj2->signal_connect (notify => sub { $notified2 = 1; });

  {
    my $freezer = Glib::Ex::FreezeNotify->new ($obj1, $obj2);
    $obj1->set (myprop_one => 1);
    $obj2->set (myprop_two => 1);
    ok (! $notified1, 'freezer alive, no notify obj1 yet');
    ok (! $notified2, 'freezer alive, no notify obj2 yet');
  }
  ok ($notified1, 'notify obj1 goes out after freezer dies');
  ok ($notified2, 'notify obj2 goes out after freezer dies');
}

{
  my $obj = Foo->new;
  my $notified = 0;
  $obj->signal_connect (notify => sub { $notified = 1; });

  eval {
    my $freezer = Glib::Ex::FreezeNotify->new ($obj);
    die "an error";
  };
  $obj->set (myprop_one => 1);
  ok ($notified, 'after a die the obj is not left frozen');
}

{
  my $obj = Foo->new;
  my $notified = 0;
  $obj->signal_connect (notify => sub { $notified = 1; });

  eval {
    my $freezer = Glib::Ex::FreezeNotify->new ($obj);
    $obj->set(bogosity => 1);
  };
  $obj->set (myprop_one => 1);
  ok ($notified, 'after a bad set() propname the obj is not left frozen');
}

# notify goes out after a die
{
  my $obj = Foo->new;
  my $notified = 0;
  my $die_notified = 'not set';
  $obj->signal_connect (notify => sub { $notified = 1; });

  local $SIG{__DIE__} = sub {
    $die_notified = $notified;
  };

  eval {
    my $freezer = Glib::Ex::FreezeNotify->new ($obj);
    $obj->set (myprop_one => 1);
    ok (! $notified, "notify hasn't gone before the die");
    die "an error";
  };
  ok ($notified, 'notify has gone out after the die');
  is ($die_notified, 0,
     'SIG{__DIE__} runs inside the eval, so the freezer object is still alive and not yet done its thaw');
}

{
  my $obj = Foo->new;
  my $freezer = Glib::Ex::FreezeNotify->new ($obj);
  Scalar::Util::weaken ($obj);
  ok (! defined $obj, "doesn't keep a hard reference to its object");
}

# doesn't keep a hard reference to either of two objects
{
  my $obj1 = Foo->new;
  my $obj2 = Foo->new;
  my $freezer = Glib::Ex::FreezeNotify->new ($obj1, $obj2);
  Scalar::Util::weaken ($obj2);
  ok (! defined $obj2, "doesn't keep a hard reference to obj1");
  Scalar::Util::weaken ($obj1);
  ok (! defined $obj1, "doesn't keep a hard reference to obj2");
}

{
  my $obj = Foo->new;
  my $notified;
  $obj->signal_connect (notify => sub { $notified = 1; });
  eval { Glib::Ex::FreezeNotify->new ($obj, 'something bad') };
  $notified = 0;
  $obj->set (myprop_one => 1);
  ok ($notified,
      "if one argument to new() is bad the rest aren't left frozen");
}

exit 0;
