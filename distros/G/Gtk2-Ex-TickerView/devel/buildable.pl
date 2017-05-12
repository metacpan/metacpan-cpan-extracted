#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

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
use Devel::FindRef;
use Devel::Peek;
use Gtk2::Ex::TickerView;

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
  print "buildable\n";

{
  $builder = undef;
  Scalar::Util::weaken ($main::XX);
  print "XX: ",$main::XX//'undef',"\n";

  print Dump ($main::XX);
  print Devel::FindRef::track \$main::XX;
  exit 0;
}


{
  my $ticker = $builder->get_object('ticker');
  $builder = undef;
  print "ticker ref ",Devel::Peek::SvREFCNT($ticker),"\n";
  Scalar::Util::weaken ($ticker);
  print "ticker ref ",Devel::Peek::SvREFCNT($ticker),"\n";

  Scalar::Util::weaken ($main::XX);
  print "ticker: ",$ticker//'undef',"\n";
  print "XX: ",$main::XX//'undef',"\n";

  print Dump ($ticker);
  print Dump ($main::XX);
  print Devel::FindRef::track \$ticker;
  print Devel::FindRef::track \$main::XX;
  exit 0;
}

{
  my $label = $builder->get_object('cellview');
  $builder = undef;
  Scalar::Util::weaken ($label);
  is ($label,   undef, 'label from buildable weakened');
  exit 0;
}

my $ticker = $builder->get_object('ticker');
isa_ok ($ticker, 'Gtk2::Ex::TickerView', 'ticker from buildable');

my $renderer = $builder->get_object('renderer');
isa_ok ($renderer, 'Gtk2::CellRendererText', 'renderer from buildable');
is_deeply ([ $ticker->GET_CELLS ], [ $renderer ],
           'GET_CELLS ticker from buildable');

my $store = Gtk2::ListStore->new ('Glib::String');
$ticker->set (model => $store);
my $iter = $store->insert_with_values (0, 0=>'foo');
$ticker->_set_cell_data ($iter);  # from Gtk2::Ex::CellLayout::Base
is ($renderer->get ('text'), 'foo',
    'renderer from buildable attribute set');

Scalar::Util::weaken ($builder);
Scalar::Util::weaken ($ticker);
Scalar::Util::weaken ($renderer);
$renderer = undef;
$builder = undef;
$store = undef;
$iter = undef;
is ($builder,  undef, 'builder weakened');
is ($ticker,   undef, 'ticker from buildable weakened');
is ($renderer, undef, 'renderer from buildable weakened');

exit 0;
