#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2013 Kevin Ryde

# This file is part of Gtk2-Ex-DateSpinner.
#
# Gtk2-Ex-DateSpinner is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-DateSpinner is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-DateSpinner.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Test::More tests => 10;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::DateSpinner::CellRenderer;

my $want_version = 9;
{
  is ($Gtk2::Ex::DateSpinner::CellRenderer::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::DateSpinner::CellRenderer->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { Gtk2::Ex::DateSpinner::CellRenderer->VERSION($want_version); 1 },
      "VERSION class check $want_version");

  my $check_version = $want_version + 1000;
  ok (! eval{Gtk2::Ex::DateSpinner::CellRenderer->VERSION($check_version); 1},
      "VERSION class check $check_version");
}

require Gtk2;
MyTestHelpers::glib_gtk_versions();

#-----------------------------------------------------------------------------
# plain creation

{
  my $renderer = Gtk2::Ex::DateSpinner::CellRenderer->new;

  ok ($renderer->VERSION >= $want_version, 'VERSION object method');
  ok (eval { $renderer->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $renderer->VERSION($check_version); 1 },
      "VERSION object check $check_version");

  require Scalar::Util;
  Scalar::Util::weaken ($renderer);
  is ($renderer, undef, 'should be garbage collected when weakened');
}

#-----------------------------------------------------------------------------
# start_editing return object

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

SKIP: {
  $have_display or skip 'no DISPLAY available', 2;

  my $toplevel = Gtk2::Window->new ('toplevel');

  my $renderer = Gtk2::Ex::DateSpinner::CellRenderer->new (editable => 1);
  my $event = Gtk2::Gdk::Event->new ('button-press');
  my $rect = Gtk2::Gdk::Rectangle->new (0, 0, 100, 100);
  my $editable = $renderer->start_editing
    ($event, $toplevel, "0", $rect, $rect, ['selected']);
  isa_ok ($editable, 'Gtk2::CellEditable',
          'start_editing return');
  $toplevel->add ($editable);
  $toplevel->remove ($editable);
  MyTestHelpers::main_iterations(); # for idle handler hack

  require Scalar::Util;
  Scalar::Util::weaken ($editable);
  is ($editable, undef, 'editable should be garbage collected when weakened');

  $toplevel->destroy;
}

exit 0;
