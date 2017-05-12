#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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

require Gtk2::Ex::KeySnooper;

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to Gtk2->init_check() unsuccessful';

plan tests => 11;

{
  my $want_version = 48;
  is ($Gtk2::Ex::KeySnooper::VERSION, $want_version, 'VERSION variable');
  is (Gtk2::Ex::KeySnooper->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Gtk2::Ex::KeySnooper->VERSION($want_version); 1 },
      "VERSION check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::KeySnooper->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

require Gtk2;
MyTestHelpers::glib_gtk_versions();

{
  my $toplevel = Gtk2::Window->new('toplevel');
  $toplevel->realize;
  my $called = 0;
  my $snooper = Gtk2::Ex::KeySnooper->new (sub { $called++;
                                                 return 0; # propagate
                                               });
  is ($called, 0);

  my $event = Gtk2::Gdk::Event::Key->new ('key-press');
  $event->window ($toplevel->window);

  Gtk2->main_do_event ($event);
  is ($called, 1, 'snooper called');

  require Scalar::Util;
  Scalar::Util::weaken ($snooper);
  is ($snooper, undef, 'garbage collected when weakened');

  Gtk2->main_do_event ($event);
  is ($called, 1, 'no call after destroy');

  $toplevel->destroy;
}

{
  my $toplevel = Gtk2::Window->new('toplevel');
  $toplevel->realize;
  my $called = 0;
  my $snooper = Gtk2::Ex::KeySnooper->new (sub { $called++;
                                                 return 0; # propagate
                                               });
  my $event = Gtk2::Gdk::Event::Key->new ('key-press');
  $event->window ($toplevel->window);

  Gtk2->main_do_event ($event);
  is ($called, 1, 'snooper called');

  $snooper->remove;
  Gtk2->main_do_event ($event);
  is ($called, 1, 'no call after remove()');

  $toplevel->destroy;
}

{
  my $toplevel = Gtk2::Window->new('toplevel');
  $toplevel->realize;
  my $called_A = 0;
  my $called_B = 0;
  my $snooper_A = Gtk2::Ex::KeySnooper->new (sub { $called_A++;
                                                   return 1; # stop
                                                 });
  my $snooper_B = Gtk2::Ex::KeySnooper->new (sub { $called_B++;
                                                   return 1; # stop
                                                 });
  my $event = Gtk2::Gdk::Event::Key->new ('key-press');
  $event->window ($toplevel->window);

  # latest installed snooper gets priority, which is probably a feature,
  # but not actually documented, so don't depend on which of A or B it is
  # that runs
  Gtk2->main_do_event ($event);
  is ($called_A + $called_B, 1, 'one snooper returns "stop"');

  $toplevel->destroy;
}

exit 0;
