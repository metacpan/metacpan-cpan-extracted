#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TickerView.
#
# Gtk2-Ex-TickerView is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-TickerView is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TickerView.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2::Ex::TickerView;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2;
MyTestHelpers::glib_gtk_versions();

Gtk2::Ex::TickerView->isa('Gtk2::Buildable')
  or plan skip_all => 'due to no Gtk2::Buildable interface';

plan tests => 6;

#------------------------------------------------------------------------------
# buildable

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<'HERE');
<interface>
  <object class="Gtk2__Ex__TickerView" id="ticker">
    <property name="width-request">200</property>
    <child>
      <object class="GtkCellRendererText" id="renderer">
        <property name="xpad">10</property>
      </object>
      <attributes>
        <attribute name="text">0</attribute>
      </attributes>
    </child>
  </object>
  <object class="GtkCellView" id="cellview">
    <property name="width-request">200</property>
    <child>
      <object class="GtkCellRendererText" id="ren2">
        <property name="xpad">10</property>
      </object>
      <attributes>
        <attribute name="text">0</attribute>
      </attributes>
    </child>
  </object>
</interface>
HERE

my $ticker = $builder->get_object('ticker');
isa_ok ($ticker, 'Gtk2::Ex::TickerView', 'ticker from buildable');

my $renderer = $builder->get_object('renderer');
isa_ok ($renderer, 'Gtk2::CellRendererText', 'renderer from buildable');
is_deeply ([ $ticker->GET_CELLS ], [ $renderer ],
           'GET_CELLS ticker from buildable');

my $store = Gtk2::ListStore->new ('Glib::String');
$ticker->set (model => $store);
my $iter = $store->append;
$store->set ($iter, 0 => 'foo');
$ticker->_set_cell_data ($iter);  # from Gtk2::Ex::CellLayout::Base
is ($renderer->get ('text'), 'foo',
    'renderer from buildable attribute set');

# Something fishy seen in gtk 2.12.1 (with gtk2-perl 1.180, 1.183 or
# 1.200) that $builder stays non-undef when weakened, though the objects
# within it weaken away as expected.  Some of the ref counting changed in
# Gtk from what the very first gtkbuilder.c versions did, so think it's a
# gtk problem already fixed, so just ignore that test.
#
Scalar::Util::weaken ($builder);
Scalar::Util::weaken ($ticker);
Scalar::Util::weaken ($renderer);
# is ($builder,  undef, 'builder weakened');
is ($ticker,   undef, 'ticker from builder weakened');
is ($renderer, undef, 'renderer from builder weakened');

exit 0;
