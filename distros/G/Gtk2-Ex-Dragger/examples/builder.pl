#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Dragger.
#
# Gtk2-Ex-Dragger is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Dragger is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Dragger.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./builder.pl
#
# This is an example of making a Dragger with Gtk2::Builder (which is new in
# Gtk 2.12), putting a label in a viewport.
#
# The class name is "Gtk2__Ex__Dragger", as usual for Gtk2-Perl package name
# to Gtk type name conversion.  The Dragger is a separate toplevel object.
# The "widget" property sets what it should act on, and hadjustment and
# vadjustment the controlling adjs for that widget.
#
# The width/height property settings are just to make something which is
# draggable.  In a real program you'd probably set_default_size() for the
# toplevel and let the children be whatever size they want.
#
# Viewport and similar widgets may make their own adjustment objects.  Does
# the builder offer a way to pick out those property values to set into
# another object like the dragger?  For now the suggestion is to create your
# own toplevel adjustment objects and set them into the viewer and the
# dragger.  See builder-internal.pl for an example of a class offering its
# adjustments as "internal-child" objects.

use 5.008;
use strict;
use warnings;
use Gtk2 1.220;
use Gtk2 '-init';
use Gtk2::Ex::Dragger;

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<"HERE");
<interface>

  <!-- GtkViewport will dynamically set the range etc in these -->
  <object class="GtkAdjustment" id="hadjustment">
  </object>
  <object class="GtkAdjustment" id="vadjustment">
  </object>

  <object class="GtkWindow" id="toplevel">
    <property name="type">toplevel</property>
    <property name="border-width">10</property>
    <property name="width-request">150</property>
    <property name="height-request">150</property>
    <signal name="destroy" handler="do_quit"/>

    <child>
      <object class="GtkViewport" id="viewport">
        <property name="hadjustment">hadjustment</property>
        <property name="vadjustment">vadjustment</property>
        <property name="border-width">0</property>

        <child>
          <object class="GtkLabel" id="label">
            <property name="label">this is some text which can be scrolled around
blah
blah
blah
blah a b c a b c a b c a b c a b c a b c a b c a b c
blah
blah
blah
blah
blah
blah
blah d e f d e f d e f d e f d e f d e f d e f d e f d e f
blah
blah
blah
blah
blah ghi ghi ghi ghi ghi ghi ghi ghi ghi ghi ghi ghi ghi ghi
blah
blah
blah
blah
a final line
</property>
            <property name="width-request">500</property>
            <property name="height-request">500</property>
            <property name="xalign">0</property>
            <property name="yalign">0</property>
          </object>
        </child>
      </object>
    </child>
  </object>

  <object class="Gtk2__Ex__Dragger" id="dragger">
    <property name="widget">viewport</property>
    <property name="hadjustment">hadjustment</property>
    <property name="vadjustment">vadjustment</property>
    <property name="cursor-name">fleur</property>
    <property name="confine">1</property>
  </object>
</interface>
HERE

sub do_quit { Gtk2->main_quit; }
$builder->connect_signals;

my $viewport = $builder->get_object('viewport');
$viewport->add_events ('button-press-mask');
$viewport->signal_connect (button_press_event =>
                           sub {
                             my ($widget, $event) = @_;
                             my $dragger = $builder->get_object('dragger');
                             $dragger->start ($event);
                             return Gtk2::EVENT_PROPAGATE;
                           });

my $toplevel = $builder->get_object('toplevel');
$toplevel->show_all;

Gtk2->main;
exit 0;
