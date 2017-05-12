#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::SyncCall;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to Gtk2->init_check() unsuccessful';
MyTestHelpers::glib_gtk_versions();

plan tests => 14;

{
  my $want_version = 48;
  is ($Gtk2::Ex::SyncCall::VERSION, $want_version, 'VERSION variable');
  is (Gtk2::Ex::SyncCall->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Gtk2::Ex::SyncCall->VERSION($want_version); 1 },
      "VERSION check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::SyncCall->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------

{
  my $timer_id = Glib::Timeout->add (120_000,   # 2 minutes in milliseconds
                                     sub { diag "Oops, timeout"; exit 1; });

  # one callback
  {
    my $called = 0;
    my $toplevel = Gtk2::Window->new('toplevel');
    $toplevel->realize;
    Gtk2::Ex::SyncCall->sync ($toplevel, sub { $called = 1;
                                               Gtk2->main_quit });
    Gtk2->main;
    is ($called, 1, 'sync callback runs');

    $toplevel->destroy;
  }

  # callback on destroy
  {
    my $called = 0;
    my $toplevel = Gtk2::Window->new('toplevel');
    $toplevel->realize;
    Gtk2::Ex::SyncCall->sync ($toplevel, sub { $called = 1; });
    $toplevel->destroy;
    is ($called, 1,
        'callbacks run when widget destroyed');
  SKIP: {
      $toplevel->can('get_display')
        or skip 'due to no get_display(), per Gtk 2.0.x', 1;
      my $display = $toplevel->get_display;
      is (undef, $display->{'Gtk2::Ex::SyncCall'});
    }
  }

  # callback on unrealize, and then as normal when re-realize
  {
    my $called = 0;
    my $toplevel = Gtk2::Window->new('toplevel');
    $toplevel->realize;
    Gtk2::Ex::SyncCall->sync ($toplevel, sub { $called = 1; });
    $toplevel->unrealize;
    is ($called, 1,
        'callbacks run when widget unrealized');
  SKIP: {
      $toplevel->can('get_display')
        or skip 'due to no get_display(), per Gtk 2.0.x', 1;
      my $display = $toplevel->get_display;
      is (undef, $display->{'Gtk2::Ex::SyncCall'},
          'no data left behind on GdkDisplay');
    }

    $called = 0;
    $toplevel->realize;
    Gtk2::Ex::SyncCall->sync ($toplevel, sub { $called = 1;
                                               Gtk2->main_quit });
    Gtk2->main;
    is ($called, 1,
        'callback runs when widget re-realized');
    $toplevel->destroy;
  }

  # two callbacks in order
  {
    my $toplevel = Gtk2::Window->new('toplevel');
    $toplevel->realize;
    my @called;
    Gtk2::Ex::SyncCall->sync ($toplevel, sub { push @called, 'one' });
    Gtk2::Ex::SyncCall->sync ($toplevel, sub { push @called, 'two';
                                               Gtk2->main_quit });
    Gtk2->main;
    is_deeply (\@called, [ 'one', 'two' ],
               'two syncs run in order');

    $toplevel->destroy;
  }

  # error trapped, further sync runs
  {
    my $toplevel = Gtk2::Window->new('toplevel');
    $toplevel->realize;

    my $called = 0;
    my $called_handler = sub {
      $called++;
      Gtk2->main_quit;
    };
    my $install_call = sub {
      Gtk2::Ex::SyncCall->sync ($toplevel, $called_handler);
      return 0; # remove source
    };
    Glib->install_exception_handler (sub {
                                       Glib::Idle->add ($install_call);
                                     });
    Gtk2::Ex::SyncCall->sync ($toplevel, sub { die });
    Gtk2::Ex::SyncCall->sync ($toplevel, sub { die });
    Gtk2->main;
    is ($called, 1,
        'new sync runs ok after an error');

    $toplevel->destroy;
  }

  is_deeply ([ Gtk2::Window->list_toplevels ], [ ],
             'no stray toplevels left by tests');

  ok (Glib::Source->remove ($timer_id), 'remove timeout');
}

exit 0;
