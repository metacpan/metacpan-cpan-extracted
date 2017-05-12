#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
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

require Gtk2::Ex::ToolItem::OverflowToDialog;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to Gtk2->init_check() unsuccessful';

plan tests => 30;

sub force_dialog {
  my ($toolitem) = @_;
  my $menuitem = $toolitem->retrieve_proxy_menu_item;
  $menuitem->activate;
  if (! $toolitem->{'dialog'}) {
    die "Oops, force_dialog() didn't make a dialog";
  } elsif (! $toolitem->{'dialog'}->mapped) {
    die "Oops, force_dialog() didn't map the dialog";
  }
  return $toolitem->{'dialog'};
}

#------------------------------------------------------------------------------
# child property

{
  my $child_widget = Gtk2::Button->new ('XYZ');
  my $toolitem =  Gtk2::Ex::ToolItem::OverflowToDialog->new
    (child => $child_widget);
  is ($toolitem->get_child, $child_widget);
}

#------------------------------------------------------------------------------
# weaken

{
  my $toolitem =  Gtk2::Ex::ToolItem::OverflowToDialog->new;
  Scalar::Util::weaken($toolitem);
  MyTestHelpers::main_iterations();
  is ($toolitem, undef, 'toolitem weaken away');
}
{
  my $child_widget = Gtk2::Button->new;
  my $toolitem =  Gtk2::Ex::ToolItem::OverflowToDialog->new
    (child_widget => $child_widget);
  Scalar::Util::weaken($toolitem);
  MyTestHelpers::main_iterations();
  is ($toolitem, undef, 'toolitem weaken away');
}
{
  my $child_widget = Gtk2::Button->new;
  my $toolitem =  Gtk2::Ex::ToolItem::OverflowToDialog->new
    (child_widget => $child_widget);
  my $menuitem = $toolitem->retrieve_proxy_menu_item;
  Scalar::Util::weaken($toolitem);
  Scalar::Util::weaken($menuitem);
  MyTestHelpers::main_iterations();
  is ($toolitem, undef, 'toolitem with menu weaken away');
  is ($menuitem, undef, 'menuitem weaken away');
}
{
  my $child_widget = Gtk2::Button->new;
  my $toolitem =  Gtk2::Ex::ToolItem::OverflowToDialog->new
    (child_widget => $child_widget);
  my $menuitem = $toolitem->retrieve_proxy_menu_item;
  my $dialog = force_dialog($toolitem);
  Scalar::Util::weaken($toolitem);
  Scalar::Util::weaken($menuitem);
  Scalar::Util::weaken($dialog);
  MyTestHelpers::main_iterations();
  is ($toolitem, undef, 'toolitem with dialog weaken away');
  is ($menuitem, undef, 'menuitem weaken away');
  is ($dialog, undef, 'dialog weaken away');
}
  # Scalar::Util::weaken($child_widget);
  # is ($child_widget, undef, 'prev child_widget weaken away');


#------------------------------------------------------------------------------
# add()

{
  my $child_widget = Gtk2::Button->new ('XYZ');
  my $toolitem =  Gtk2::Ex::ToolItem::OverflowToDialog->new;
  $toolitem->add ($child_widget);
  is ($toolitem->get_child, $child_widget, 'add() - get_child');
  is ($toolitem->get('child_widget'), $child_widget, 'add() - child_widget');

  force_dialog($toolitem);
  is ($toolitem->get_child, undef,
      'get_child - undef when in dialog');
  is ($toolitem->get('child_widget'), $child_widget,
      'child_widget prop - when in dialog');

  my $new_child_widget = Gtk2::Button->new ('ABC');

  $toolitem->add ($new_child_widget);
  is ($toolitem->get_child, undef,
      'add() while in dialog - get_child');
  is ($toolitem->get('child_widget'), $new_child_widget,
      'add() while in dialog - child_widget');
}

#------------------------------------------------------------------------------
# child-widget property

{
  my $child_widget = Gtk2::Button->new ('XYZ');
  my $toolitem =  Gtk2::Ex::ToolItem::OverflowToDialog->new
    (child_widget => $child_widget);
  is ($toolitem->get_child, $child_widget, 'get_child - initial');
  is ($toolitem->get('child_widget'), $child_widget, 'child_widget - initial');

  $toolitem->set (child_widget => undef);
  is ($toolitem->get_child, undef, 'set undef - get_child');
  is ($toolitem->get('child_widget'), undef, 'set undef - child_widget');
}
{
  my $child_widget = Gtk2::Button->new ('XYZ');
  my $toolitem =  Gtk2::Ex::ToolItem::OverflowToDialog->new;

  $toolitem->set_child_widget ($child_widget);
  is ($toolitem->get_child, $child_widget, 'set_child_widget() - get_child');
  is ($toolitem->get('child_widget'), $child_widget,
      'set_child_widget() - child_widget property');

  force_dialog($toolitem);
  is ($toolitem->get_child, undef,
      'get_child - undef when in dialog');
  is ($toolitem->get('child_widget'), $child_widget,
      'child_widget prop - when in dialog');

  $toolitem->set (child_widget => undef);
  is ($toolitem->get_child, undef,
      'set undef with dialog - get_child');
  is ($toolitem->get('child_widget'), undef,
      'set undef with dialog - child_widget');
}

#-----------------------------------------------------------------------------
# initial menuitem "sensitive" property

{
  my $toolitem = Gtk2::Ex::ToolItem::OverflowToDialog->new;
  my $menuitem = $toolitem->retrieve_proxy_menu_item;
  is (!! $menuitem->get('sensitive'), !! 1, 'menuitem sensitive initial 0');
}
{
  my $toolitem = Gtk2::Ex::ToolItem::OverflowToDialog->new
    (sensitive => 0);
  my $menuitem = $toolitem->retrieve_proxy_menu_item;
  is (!! $menuitem->get('sensitive'), !! 0, 'menuitem sensitive initial 0');
}

#-----------------------------------------------------------------------------
# propagate "sensitive" property

{
  my $toolitem = Gtk2::Ex::ToolItem::OverflowToDialog->new;
  my $menuitem = $toolitem->retrieve_proxy_menu_item;
  $toolitem->set (sensitive => 0);
  is (!! $menuitem->get('sensitive'), !! 0, 'menuitem sensitive propagate 0');
  $toolitem->set (sensitive => 1);
  is (!! $menuitem->get('sensitive'), !! 1, 'menuitem sensitive propagate 1');
}

#-----------------------------------------------------------------------------
# "tooltip-text" propagate

SKIP: {
  my $toolitem = Gtk2::Ex::ToolItem::OverflowToDialog->new;
  $toolitem->find_property('tooltip-text')
    or skip "due to no tooltip-text property", 1;

  my $menuitem = $toolitem->retrieve_proxy_menu_item;
  my $str = 'Blah blah tooltip text.';
  $toolitem->set (tooltip_text => $str);
  is ($menuitem->get ('tooltip-text'), $str, 'menuitem tooltip-text');
}

#-----------------------------------------------------------------------------
# "overflow-mnemonic"

{
  my $toolitem = Gtk2::Ex::ToolItem::OverflowToDialog->new;
  $toolitem->set (overflow_mnemonic => '_Foo');
  my $menuitem = $toolitem->retrieve_proxy_menu_item;
  $toolitem->set (overflow_mnemonic => '_Bar');
  force_dialog($toolitem);
  $toolitem->set (overflow_mnemonic => '_Quux');
  ok (1, 'overflow-mnemonic setting');
}

exit 0;
