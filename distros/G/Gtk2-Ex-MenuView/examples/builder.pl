#!/usr/bin/perl -w

# Copyright 2007, 2008, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-MenuView.
#
# Gtk2-Ex-MenuView is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-MenuView is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-MenuView.  If not, see <http://www.gnu.org/licenses/>.


# This is an example of making a MenuView with Gtk2::Builder.  The class
# name is "Gtk2__Ex__MenuView" per Perl-Gtk2 package name to Gtk type name
# conversion.
#
# Notice the MenuView is a top-level object, as usual for Gtk2::Window
# classes.  It's then hooked into the GUI as the submenu of an item in the
# toplevel MenuBar.
#
# The ListStore model and its data are created in the builder here, but in a
# real program it's more likely the data would be from some external source,
# since the whole point of MenuView is to display dynamic things.
#
# Builder doesn't really add much for MenuView.  You still have to write an
# item-create-or-update handler.  But builder does swap tedious and
# repetitive code making widgets for tedious and repetitive pseudo-xml
# making widgets!
#

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::MenuView;

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<'HERE');
<interface>
  <object class="GtkListStore" id="liststore">
    <columns>
      <column type="gchararray"/>
    </columns>
    <data>
      <row> <col id="0">Choice one</col> </row>
      <row> <col id="0">Choice the second</col> </row>
      <row> <col id="0">The choice third</col> </row>
    </data>
  </object>

  <object class="Gtk2__Ex__MenuView" id="menu">
    <property name="model">liststore</property>
    <signal name="item-create-or-update" handler="do_item_create_or_update"/>
    <signal name="activate" handler="do_activate"/>
  </object>

  <object class="GtkWindow" id="toplevel">
    <property name="type">toplevel</property>
    <signal name="destroy" handler="do_quit"/>
    <child>
      <object class="GtkMenuBar" id="menubar">
        <child>
          <object class="GtkMenuItem" id="popup_item">
            <property name="submenu">menu</property>
            <child>
              <object class="GtkLabel" id="popup_label">
                <property name="label">Click to Popup</property>
              </object>
            </child>
          </object>
        </child>
      </object>
    </child>
  </object>
</interface>
HERE

sub do_item_create_or_update {
  my ($menuview, $item, $model, $path, $iter) = @_;
  # don't bother updating existing $item, just create a new one each time
  my $str = $model->get($iter, 0);  # display column 0
  return Gtk2::MenuItem->new_with_label ($str);
}
sub do_activate {
  my ($menuview, $item, $model, $path, $iter) = @_;
  print "activate path = ", $path->to_string, "\n";
  print "    model str = ", $model->get($iter,0), "\n";
}
sub do_quit {
  Gtk2->main_quit;
}

$builder->connect_signals;

$builder->get_object('toplevel')->show_all;
Gtk2->main;
exit 0;
