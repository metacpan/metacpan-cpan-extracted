#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

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

require Gtk2::Ex::MenuBits;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to Gtk2->init_check() unsuccessful';

plan tests => 21;

{
  my $want_version = 48;
  is ($Gtk2::Ex::MenuBits::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::MenuBits->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { Gtk2::Ex::MenuBits->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::MenuBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

{
  my $menu = Gtk2::Menu->new;
  my $widget = Gtk2::Label->new;
  $widget->show;
  is_deeply ([ Gtk2::Ex::MenuBits::position_widget_topcentre
               ($menu, -12345, -6789, $widget) ],
             [ -12345, -6789, 1 ],
             'when not in a toplevel');

  my $toplevel = Gtk2::Window->new('toplevel');
  $toplevel->add ($widget);
  is_deeply ([ Gtk2::Ex::MenuBits::position_widget_topcentre
               ($menu, -12345, -6789, $widget) ],
             [ -12345, -6789, 1 ],
             'when not realized');

  $toplevel->show_all;
  # MyTestHelpers::main_iterations();
  # diag $toplevel->window;
  # diag $widget->window;
  my ($x,$y,$push_in) = Gtk2::Ex::MenuBits::position_widget_topcentre
    ($menu, -123456, -654321, $widget);
  isnt ($x, -123456,
        'with show_all()');

  $toplevel->destroy;
}

#------------------------------------------------------------------------------
# mnemonic_escape()

is (Gtk2::Ex::MenuBits::mnemonic_escape(''), '');
is (Gtk2::Ex::MenuBits::mnemonic_escape('_'), '__');
is (Gtk2::Ex::MenuBits::mnemonic_escape('__'), '____');
is (Gtk2::Ex::MenuBits::mnemonic_escape('X_'), 'X__');
is (Gtk2::Ex::MenuBits::mnemonic_escape('_ X _ Y _'), '__ X __ Y __');

#------------------------------------------------------------------------------
# mnemonic_undo()

is (Gtk2::Ex::MenuBits::mnemonic_undo(''), '');
is (Gtk2::Ex::MenuBits::mnemonic_undo('__'), '_');
is (Gtk2::Ex::MenuBits::mnemonic_undo('____'), '__');
is (Gtk2::Ex::MenuBits::mnemonic_undo('X_'), 'X_'); # invalid, but passes
is (Gtk2::Ex::MenuBits::mnemonic_undo('X__'), 'X_');
is (Gtk2::Ex::MenuBits::mnemonic_undo('_File'), 'File');
is (Gtk2::Ex::MenuBits::mnemonic_undo('Save _As'), 'Save As');
is (Gtk2::Ex::MenuBits::mnemonic_undo('_X_Y_Z__'), 'XYZ_');
is (Gtk2::Ex::MenuBits::mnemonic_undo('X_______Y'), 'X___Y');

exit 0;
