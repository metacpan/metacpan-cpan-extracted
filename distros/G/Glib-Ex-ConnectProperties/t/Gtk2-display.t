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
use Glib::Ex::ConnectProperties;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

eval { require Gtk2 }
  or plan skip_all => "due to Gtk2 module not available -- $@";
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => "due to no DISPLAY";

plan tests => 23;

MyTestHelpers::glib_gtk_versions();


## no critic (ProtectPrivateSubs)

#-----------------------------------------------------------------------------
# Gtk2::Border struct from Gtk2::Entry
#
# Crib: Gtk 2.16 needs gtk_init() before creating a Gtk2::Entry, or it gives
# a slew of warnings, hence this test here instead of Gtk2.t.

{ my $entry = Gtk2::Entry->new;
  my $pname = 'inner-border';
  my $pspec = $entry->find_property ($pname)
    or die "Oops, Gtk2::Entry doesn't have property '$pname'";
  diag "Gtk2::Entry $pname pspec ",ref $pspec,
    ", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       {left=>1,right=>2,top=>3,bottom=>4},
       {left=>1,right=>2,top=>3,bottom=>4}));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       {left=>1,right=>2,top=>3,bottom=>4},
       {left=>0,right=>2,top=>3,bottom=>4}));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       {left=>1,right=>2,top=>3,bottom=>4},
       {left=>1,right=>0,top=>3,bottom=>4}));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       {left=>1,right=>2,top=>3,bottom=>4},
       {left=>1,right=>2,top=>0,bottom=>4}));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       {left=>1,right=>2,top=>3,bottom=>4},
       {left=>1,right=>2,top=>3,bottom=>0}));

  {
    my $border = $entry->get ($pname); # undef by default
    ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $border,$border));
  }
  {
    $entry->set ($pname, {left=>1,right=>2,top=>3,bottom=>4});
    my $border = $entry->get ($pname); # undef by default
    ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $border,$border));
  }
}

#-----------------------------------------------------------------------------
# strv from AboutDialog

{ my $about = Gtk2::AboutDialog->new;
  my $pname = 'artists';
  my $pspec = $about->find_property ($pname)
    or die "Oops, Gtk2::AboutDialog doesn't have property '$pname'";
  diag "Gtk2::AboutDialog pspec ",ref $pspec,
    ", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,undef));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, [],undef));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,[]));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, [],[]));

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, ['x'],['x']));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, ['x'],[]));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, ['x'],undef));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, [],['x']));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,['x']));

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, ['a','b'],['a','b']));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, ['a','b'],['a','x']));
}

#-----------------------------------------------------------------------------
# GdkCursor boxed

{ my $pspec = Glib::ParamSpec->boxed ('foo','foo','blurb',
                                      'Gtk2::Gdk::Cursor',['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  my $c1 = Gtk2::Gdk::Cursor->new ('watch');
  my $c1b = Gtk2::Gdk::Cursor->new ('watch');
  my $c2 = Gtk2::Gdk::Cursor->new ('hand1');
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $c1,$c1));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $c1,$c1b));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $c1,$c2));

 SKIP: {
    my $default_display = (Gtk2::Gdk::Display->can('get_default') # new in 2.2
                           && Gtk2::Gdk::Display->get_default);
    if (! $default_display) {
      skip "due to no default display", 2;
    }
    my $window = $default_display->get_default_screen->get_root_window;
    my $m = Gtk2::Gdk::Bitmap->create_from_data ($window, "\0", 1, 1);
    my $color = Gtk2::Gdk::Color->new (0,0,0);
    my $cp1 = Gtk2::Gdk::Cursor->new_from_pixmap ($m,$m, $color,$color, 0,0);
    my $cp2 = Gtk2::Gdk::Cursor->new_from_pixmap ($m,$m, $color,$color, 0,0);
    ok (Glib::Ex::ConnectProperties::_pspec_equal
        ($pspec, $cp1,$cp1,
         'same cursor from bitmap'));
    ok (! Glib::Ex::ConnectProperties::_pspec_equal
        ($pspec, $cp1,$cp2,
         'different cursors from bitmap'));
  }
}

exit 0;
