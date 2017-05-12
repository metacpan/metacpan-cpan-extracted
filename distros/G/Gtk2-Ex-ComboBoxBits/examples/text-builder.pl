#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-ComboBoxBits.
#
# Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ComboBoxBits.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl text-builder.pl
#
# This is an example of making a Text combobox with Gtk2::Builder (which is
# new in Gtk 2.12).

# The class name is "Gtk2__Ex__ComboBox__Text", as usual for Gtk2-Perl
# package name to Gtk type name conversion in the builder.
#
# The append-text property is a handy way to fill the combobox with desired
# choices for the user.  Once they're added the active-text property can
# then be set to the initially active choice.
#
# active-text is by string value.  The usual ComboBox "active" property can
# set the active by number too.  If for example the first choice is always
# the desired one then it may be easier to write "0" than copy the string,
#
#     <property name="active">0</property>
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
      <object class="Gtk2__Ex__ComboBox__Text" id="combo">
        <property name="append-text">First Choice</property>
        <property name="append-text">Second Choice</property>
        <property name="append-text">Choice the Third</property>

        <property name="active-text">Second Choice</property>
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
