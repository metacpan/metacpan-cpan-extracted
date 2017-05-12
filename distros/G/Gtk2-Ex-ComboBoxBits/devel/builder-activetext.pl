#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-ComboBoxBits.
#
# Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ComboBoxBits.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl builder-activatetext.pl
#

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::ComboBox::Text;

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<'HERE');
<interface>
  <object class="GtkWindow" id="toplevel">
    <property name="type">toplevel</property>
    <signal name="destroy" handler="do_quit"/>
    <child>
      <object class="GtkHBox" id="hbox">
        <child>
          <object class="Gtk2__Ex__ComboBox__Text" id="combobox">
            <property name="append-text">First Choice</property>
            <property name="append-text">Second Choice</property>
            <property name="append-text">Choice the Third</property>
            <property name="active-text">Second Choice</property>
          </object>
        </child>
        <child>
          <object class="GtkButton" id="quit">
            <property name="label">gtk-quit</property>
            <property name="use-stock">TRUE</property>
            <signal name="clicked" handler="do_quit"/>
          </object>
        </child>
      </object>
    </child>
  </object>
</interface>
HERE

sub do_quit { Gtk2->main_quit; }
$builder->connect_signals;

$builder->get_object('toplevel')->show_all;
Gtk2->main;
exit 0;
