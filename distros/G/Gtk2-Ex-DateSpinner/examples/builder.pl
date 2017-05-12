#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2013 Kevin Ryde

# This file is part of Gtk2-Ex-DateSpinner.
#
# Gtk2-Ex-DateSpinner is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-DateSpinner is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-DateSpinner.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl builder.pl
#
# This is an example of making a datespinner in a GUI with Gtk2::Builder
# (which is new in Gtk 2.12).  The class name is "Gtk2__Ex__DateSpinner", as
# usual for Gtk2-Perl package name to Gtk type name conversion.  There's
# nothing builder-specific in DateSpinner, it's all inherited from the usual
# builder widget handling.

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::DateSpinner;

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<'HERE');
<interface>
  <object class="GtkWindow" id="toplevel">
    <property name="type">toplevel</property>
    <signal name="destroy" handler="do_quit"/>
    <child>
      <object class="GtkHBox" id="hbox">
        <child>
          <object class="Gtk2__Ex__DateSpinner" id="datespinner">
            <property name="value">2008-09-01</property>
            <signal name="notify::value" handler="do_notify_value"/>
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

sub do_quit {
  Gtk2->main_quit;
}
sub do_notify_value {
  my ($datespinner, $pspec) = @_;
  print "datespinner value now ", $datespinner->get('value'), "\n";
}
$builder->connect_signals;

$builder->get_object('toplevel')->show_all;
Gtk2->main;
exit 0;
