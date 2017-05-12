#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetCursor.
#
# Gtk2-Ex-WidgetCursor is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetCursor is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetCursor.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./builder.pl
#
# This is an example of putting multiple widgets into a single WidgetCursor
# with Gtk2::Builder (new in Gtk 2.12), using the WidgetCursor "add-widget"
# pseudo-property.
#
# See builder.pl for a single-widget.

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::WidgetCursor;

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<"HERE");
<interface>

  <object class="GtkWindow" id="toplevel">
    <property name="type">toplevel</property>
    <signal name="destroy" handler="do_quit"/>
    <child>
      <object class="GtkHBox" id="hbox">

        <child>
          <object class="GtkEventBox" id="ebox1">
            <child>
              <object class="GtkLabel" id="label1">
                <property name="label">Boat\nCursor</property>
                <property name="xpad">10</property>
                <property name="ypad">10</property>
              </object>
            </child>
          </object>
        </child>

        <child>
          <object class="GtkLabel" id="label">
            <property name="label">Nothing\nHere</property>
            <property name="xpad">10</property>
          </object>
        </child>

        <child>
          <object class="GtkEventBox" id="ebox2">
            <child>
              <object class="GtkLabel" id="label2">
                <property name="label">Boat\nAgain</property>
                <property name="xpad">10</property>
              </object>
            </child>
          </object>
        </child>
      </object>
    </child>
  </object>

  <object class="Gtk2__Ex__WidgetCursor" id="wcursor">
    <property name="active">1</property>
    <property name="cursor-name">boat</property>
    <property name="add-widget">ebox1</property>
    <property name="add-widget">ebox2</property>
  </object>

</interface>
HERE

sub do_quit { Gtk2->main_quit; }
$builder->connect_signals;

$builder->get_object('toplevel')->show_all;
Gtk2->main;
exit 0;
