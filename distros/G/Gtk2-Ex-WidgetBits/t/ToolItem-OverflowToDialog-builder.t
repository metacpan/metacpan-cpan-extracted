#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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

require Gtk2::Ex::ToolItem::OverflowToDialog;

use Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';

Gtk2::Ex::ToolItem::OverflowToDialog->isa('Gtk2::Buildable')
  or plan skip_all => 'due to no Gtk2::Buildable interface';

plan tests => 8;

#------------------------------------------------------------------------------
# buildable

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<'HERE');
<interface>
  <object class="Gtk2__Ex__ToolItem__OverflowToDialog" id="toolitem">
    <child internal-child="overflow_menuitem">
      <object class="GtkMenuItem" id="oi">
        <property name="right-justified">1</property>
      </object>
    </child>
    <child internal-child="dialog">
      <object class="GtkDialog" id="dd">
        <property name="default-height">123</property>
      </object>
    </child>
  </object>
</interface>
HERE

my $toolitem = $builder->get_object('toolitem');
isa_ok ($toolitem, 'Gtk2::Ex::ToolItem::OverflowToDialog',
        'toolitem from buildable');

my $menuitem = $toolitem->retrieve_proxy_menu_item;
isa_ok ($menuitem, 'Gtk2::MenuItem', 'overflow menuitem');
is ($menuitem && $menuitem->get('right-justified'), 1,
    'overflow menuitem right-justified');

my $dialog = Gtk2::Ex::ToolItem::OverflowToDialog::_dialog($toolitem);
isa_ok ($dialog, 'Gtk2::Dialog', 'dialog');
is ($dialog->get('default-height'), 123,
    'dialog default-height');

# Something fishy seen in gtk 2.12.1 (with gtk2-perl 1.180, 1.183 or
# 1.200) that $builder stays non-undef when weakened, though the objects
# within it weaken away as expected.  Some of the ref counting changed in
# Gtk from what the very first gtkbuilder.c versions did, so think it's a
# gtk problem already fixed, so just ignore that test.
#
Scalar::Util::weaken ($builder);
Scalar::Util::weaken ($toolitem);
Scalar::Util::weaken ($menuitem);
Scalar::Util::weaken ($dialog);
# is ($builder,  undef, 'builder weakened');
is ($toolitem, undef, 'toolitem from builder weakened');
is ($menuitem, undef, 'overflow menuitem from builder weakened');
is ($dialog, undef, 'dialog from builder weakened');

exit 0;
