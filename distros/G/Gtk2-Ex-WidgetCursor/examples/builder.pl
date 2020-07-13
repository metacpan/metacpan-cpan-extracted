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
# This is an example of making a WidgetCursor with Gtk2::Builder (new in
# Gtk 2.12).
#
# The class name is "Gtk2__Ex__WidgetCursor", as usual for Gtk2-Perl package
# name to Gtk type name conversion.  The WidgetCursor is a separate toplevel
# object and the "widget" property sets what it should act on.  You can
# retrieve the WidgetCursor with $builder->get_object() in the usual way to
# later change its "active" setting or cursor etc.
#
# The cursor to display can be set with either the "cursor-name" or
# "cursor-object" properties.  The generic Perl scalar "cursor" property
# can't be used from a Builder (as of Gtk 2.20) as there's no hook to parse
# a string from the interface description into a Perl scalar value.
#
# See builder-add.pl for adding multiple widgets to a WidgetCursor.

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::WidgetCursor;

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<"HERE");
<interface>

  <object class="GtkWindow" id="toplevel">
    <property name="type">toplevel</property>
    <property name="border-width">20</property>
    <signal name="destroy" handler="do_quit"/>

    <child>
      <object class="GtkLabel" id="label">
        <property name="label">Boat Cursor</property>
      </object>
    </child>
  </object>

  <object class="Gtk2__Ex__WidgetCursor" id="wcursor">
    <property name="widget">toplevel</property>
    <property name="active">1</property>
    <property name="cursor-name">boat</property>
  </object>

</interface>
HERE

sub do_quit { Gtk2->main_quit; }
$builder->connect_signals;

$builder->get_object('toplevel')->show_all;
Gtk2->main;
exit 0;
