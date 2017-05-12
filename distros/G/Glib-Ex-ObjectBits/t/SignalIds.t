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
use Glib::Ex::SignalIds;
use Test::More tests => 22;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Glib;
MyTestHelpers::glib_gtk_versions();

# version number
{
  my $want_version = 16;
  is ($Glib::Ex::SignalIds::VERSION, $want_version, 'VERSION variable');
  is (Glib::Ex::SignalIds->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Glib::Ex::SignalIds->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  ok (! eval { Glib::Ex::SignalIds->VERSION($want_version + 1000); 1 },
      "VERSION class check " . ($want_version + 1000));

  my $obj = MyClass->new;
  my $sigs = Glib::Ex::SignalIds->new ($obj);
  is ($sigs->VERSION, $want_version, 'VERSION object method');
  ok (eval { $sigs->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $sigs->VERSION($want_version + 1000); 1 },
      "VERSION object check " . ($want_version + 1000));
}


#------------------------------------------------------------------------------

{
  package MyClass;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
        properties => [ Glib::ParamSpec->int
                        ('myprop',
                         'myprop',
                         'Blurb',
                         0, 100, 50,
                         Glib::G_PARAM_READWRITE) ];
}

#------------------------------------------------------------------------------
# new and DESTROY

# the SignalIds object gets garbage collected when weakened
{
  my $obj = MyClass->new;
  my $sigs = Glib::Ex::SignalIds->new
    ($obj, $obj->signal_connect (notify => sub {}));
  require Scalar::Util;
  Scalar::Util::weaken ($sigs);
  is ($sigs, undef);
}

# the target object gets garbage collected when weakened
{
  my $obj = MyClass->new;
  my $sigs = Glib::Ex::SignalIds->new
    ($obj, $obj->signal_connect (notify => sub {}));
  require Scalar::Util;
  Scalar::Util::weaken ($obj);
  is ($obj, undef,
      'target object garbage collected when weakened');
}

# the held signal is disconnected when the SignalIds destroyed
{
  my $signalled;
  my $obj = MyClass->new;
  my $sigs = Glib::Ex::SignalIds->new
    ($obj, $obj->signal_connect (notify => sub { $signalled = 1 }));

  $signalled = 0;
  $obj->set(myprop => 1);
  ok ($signalled);

  $sigs = undef;

  $signalled = 0;
  $obj->set(myprop => 1);
  ok (! $signalled);
}

# two held signals disconnected
{
  my $signalled1;
  my $signalled2;
  my $obj = MyClass->new;
  my $sigs = Glib::Ex::SignalIds->new
    ($obj,
     $obj->signal_connect (notify => sub { $signalled1 = 1 }),
     $obj->signal_connect (notify => sub { $signalled2 = 1 }));

  $signalled1 = 0;
  $signalled2 = 0;
  $obj->set(myprop => 1);
  ok ($signalled1);
  ok ($signalled2);

  $sigs = undef;

  $signalled1 = 0;
  $signalled2 = 0;
  $obj->set(myprop => 1);
  ok (! $signalled1);
  ok (! $signalled2);
}

# SignalIds can cope if held signal is disconnected elsewhere
{
  diag "when id disconnected from elsewhere";
  my $obj = MyClass->new;
  my $id = $obj->signal_connect (notify => sub { });
  my $sigs = Glib::Ex::SignalIds->new ($obj, $id);

  $obj->signal_handler_disconnect ($id);
  $sigs->disconnect;
}

# No, nothing in disconnect() to handle id==0.  Could think about something
# in new()/add() to keep them out in the first place, but a wrong signal
# name provokes a glib warning, leave that to the application to get it
# right.
#
# In Glib 2.22.4 signal_handler_is_connected() quietly says false for id==0,
# but back in Glib 2.4 it provoked a g_assert warning.
#
# # SignalIds can cope with 0 return from unknown signal name
# {
#   diag "when id==0 from unknown signal name";
#   my $obj = MyClass->new;
#   my $id = 0;
#   my $sigs = Glib::Ex::SignalIds->new ($obj, $id);
#   if (defined &explain) { diag explain $sigs; }
#   $sigs->disconnect;
# }

eval { Glib::Ex::SignalIds->new (123); };
ok ($@, 'notice number as first arg');

eval { Glib::Ex::SignalIds->new ([]); };
ok ($@, 'notice ref as first arg');

eval { Glib::Ex::SignalIds->new (bless [], 'bogosity'); };
ok ($@, 'notice wrong blessed as first arg');

#------------------------------------------------------------------------------
# object(), ids(), add()

{
  my $obj = MyClass->new;
  my $id = $obj->signal_connect (notify => sub {});
  my $sigs = Glib::Ex::SignalIds->new ($obj, $id);
  is ($sigs->object, $obj, 'object()');
  is_deeply ([$sigs->ids], [$id], 'ids()');
}

{
  my $obj = MyClass->new;
  my $sigs = Glib::Ex::SignalIds->new ($obj);
  is_deeply ([$sigs->ids], [], 'ids() empty');
  my $id = $obj->signal_connect (notify => sub {});
  $sigs->add ($id);
  is_deeply ([$sigs->ids], [$id], 'ids() empty');
}

exit 0;
