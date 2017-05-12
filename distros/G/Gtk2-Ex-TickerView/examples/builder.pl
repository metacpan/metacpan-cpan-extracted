#!/usr/bin/perl -w

# Copyright 2007, 2008, 2010 Kevin Ryde

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


# This is an example of making a TickerView in a GUI with Gtk2::Builder.
# You must have Gtk2-Perl compiled against Gtk 2.12 or newer to use this.
#
# The class name is "Gtk2__Ex__TickerView", as usual for Gtk2-Perl package
# name to Gtk type name conversion.  A cell renderer is added as a "child"
# of the ticker, with <attributes> to have renderer properties from model
# columns.

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::TickerView;

my $builder = Gtk2::Builder->new;
$builder->add_from_string ('
<interface>
  <object class="GtkListStore" id="liststore">
    <columns>
      <column type="gchararray"/>
    </columns>
    <data>
      <row> <col id="0">* First item</col> </row>
      <row> <col id="0">* Second item</col> </row>
      <row> <col id="0">* Item the third</col> </row>
    </data>
  </object>

  <object class="GtkWindow" id="toplevel">
    <property name="type">toplevel</property>
    <signal name="destroy" handler="do_quit"/>
    <child>
      <object class="GtkHBox" id="hbox">

        <child>
          <object class="Gtk2__Ex__TickerView" id="ticker">
            <property name="model">liststore</property>
            <property name="width-request">200</property>
            <child>
              <object class="GtkCellRendererText" id="renderer">
                <property name="xpad">10</property>
                <property name="underline">single</property>
              </object>
              <attributes>
                <attribute name="text">0</attribute>
              </attributes>
            </child>
          </object>
        </child>

        <child>
          <object class="GtkButton" id="quit_button">
            <property name="label">gtk-quit</property>
            <property name="use-stock">TRUE</property>
            <signal name="clicked" handler="do_quit"/>
          </object>
          <packing>
            <property name="expand">FALSE</property>
            <property name="fill">FALSE</property>
          </packing>
        </child>
      </object>
    </child>
  </object>
</interface>
');

sub do_quit { Gtk2->main_quit; }
$builder->connect_signals;

$builder->get_object('toplevel')->show_all;
Gtk2->main;
exit 0;
