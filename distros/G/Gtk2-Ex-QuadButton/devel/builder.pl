#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-QuadButton.
#
# Gtk2-Ex-QuadButton is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-QuadButton is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-QuadButton.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./builder.pl
#
# This is an example of making a QuadButton in a GUI with Gtk2::Builder (which
# is new in Gtk 2.12).  The class name is "Gtk2__Ex__QuadButton", as usual for
# Gtk2-Perl package name to Gtk type name conversion.  There's nothing
# builder-specific in QuadButton, it's all inherited from the usual builder
# widget handling.
#
# The builder can create the underlying GtkAdjustment object too, though
# note that the <property> setting of the initial "value" gets clamped to
# the upper/lower range and so generally the value should be set after upper
# and lower.

use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::QuadButton::Scroll;

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<'HERE');
<interface>
  <object class="GtkAdjustment" id="adj">
    <property name="lower">-100</property>
    <property name="upper">100</property>
    <property name="value">-5</property>
    <property name="page-size">12</property>
    <property name="page-increment">10</property>
    <property name="step-increment">1</property>
  </object>

  <object class="GtkWindow" id="toplevel">
    <property name="type">toplevel</property>
    <property name="default-height">300</property>
    <signal name="destroy" handler="do_quit"/>
    <child>
      <object class="GtkHBox" id="hbox">

        <child>
          <object class="Gtk2__Ex__QuadButton__Scroll" id="qbs">
            <property name="vadjustment">adj</property>
          </object>
        </child>

        <child>
          <object class="GtkVScrollbar" id="scrollbar">
            <property name="adjustment">adj</property>
          </object>
          <packing>
            <property name="expand">0</property>
            <property name="fill">0</property>
          </packing>
        </child>

      </object>
    </child>
  </object>
</interface>
HERE

sub do_quit {
  Gtk2->main_quit;
}
$builder->connect_signals;

$builder->get_object('toplevel')->show_all;
Gtk2->main;
exit 0;
