#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Clock.
#
# Gtk2-Ex-Clock is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Clock is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Clock.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./builder.pl
#
# This is an example of making a couple of clock widgets in a GUI with
# Gtk2::Builder.  The class name is "Gtk2__Ex__Clock" as usual for Gtk2-Perl
# package name to Gtk type name conversion.  There's nothing
# builder-specific in the Clock, it's all inherited from the usual builder
# widget handling.
#
# It's not possible to set the "timezone" property to a DateTime::TimeZone
# object through the builder, but it is possible to set the
# "timezone-string" property to a $ENV{TZ} setting.  The "clock2" widget
# below does that to show Greenwich Mean Time.

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::Clock;

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<'HERE');
<interface>
  <object class="GtkWindow" id="toplevel">
    <property name="type">toplevel</property>
    <signal name="destroy" handler="do_quit"/>
    <child>
      <object class="GtkVBox" id="vbox">
        <property name="spacing">5</property>

        <child>
          <object class="Gtk2__Ex__Clock" id="clock1">
            <property name="xpad">10</property>  <!-- per GtkMisc -->
            <property name="ypad">3</property>
          </object>
        </child>

        <child>
          <object class="Gtk2__Ex__Clock" id="clock2">
            <property name="format">(GMT %H:%M:%S)</property>
            <property name="timezone-string">GMT</property>
          </object>
        </child>

        <child>
          <object class="GtkButton" id="quit_button">
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
