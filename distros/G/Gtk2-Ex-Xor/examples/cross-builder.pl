#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Xor.
#
# Gtk2-Ex-Xor is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Xor is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Xor.  If not, see <http://www.gnu.org/licenses/>.


# This is example of using Gtk2::Builder to create a crosshair.  The object
# type is "Gtk2__Ex__CrossHair" as usual for Perl-Gtk class name to GType
# name mapping.
#
# The crosshair is a separate toplevel object and the "widget" property sets
# where it will draw.  In this program there's two widgets drawn and the
# "add-widget" pseudo-property is used to add them both in.  The "widgets"
# property is no good as it's a Perl scalar and they can't be set from
# builder XML as of Perl-Gtk 1.240.
#
# The "foreground-name" property on the crosshair can set the crosshair
# colour.  "foreground-gdk" also works, and verifies the colour name is
# known, but it allocates the colour in the default colormap, which is
# unnecessary.
#
# Starting the crosshair must be done from code in a signal handler, getting
# the crosshair object out of the builder.  Here it's a do_button_press()
# when button 1 is pressed.
#
# Button events must be selected on the target widget to make that work.
# The usual widget "events" property can be set if the target widget doesn't
# already select the necessary press, motion, release masks.
# 

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::CrossHair;
use Data::Dumper;

Gtk2::Rc->parse_string (<<'HERE');
style "my_style" {
  # white on black
  fg[NORMAL]        = { 0.0, 1.0, 1.0 }
  bg[NORMAL]        = { 0, 0, 0 }
}
class "GtkDrawingArea" style:application "my_style"
HERE

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<'HERE');
<interface>
  <object class="GtkWindow" id="toplevel">
    <property name="type">toplevel</property>
    <property name="events">button-press-mask</property>
    <signal name="button-press-event" handler="do_button_press"/>
    <signal name="destroy" handler="do_quit"/>

    <child>
      <object class="GtkVBox" id="vbox">
        <child>
          <object class="GtkDrawingArea" id="draw1">
          <property name="height-request">50</property>
          <property name="width-request">100</property>
          <property name="events">button-press-mask | button-motion-mask
                                  | button-release-mask</property>
          </object>
        </child>

        <child>
          <object class="GtkLabel" id="label">
            <property name="xpad">10</property>
            <property name="label">
CrossHair with GtkBuilder.
Press and drag button 1 in either of the drawing
areas above and below to see the crosshair.
</property>
          </object>
        </child>

        <child>
          <object class="GtkDrawingArea" id="draw2">
          <property name="height-request">50</property>
          <property name="width-request">100</property>
          <property name="events">button-press-mask | button-motion-mask
                                  | button-release-mask</property>
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

  <object class="Gtk2__Ex__CrossHair" id="crosshair">
    <property name="add-widget">draw1</property>
    <property name="add-widget">draw2</property>
    <property name="foreground-name">pink</property>
  </object>
</interface>
HERE

sub do_button_press {
  my ($toplevel, $event) = @_;
  if ($event->button == 1) {
    my $crosshair = $builder->get_object('crosshair');
    $crosshair->start ($event);
    print "CrossHair started\n";
  }
  return 0; # Gtk2::EVENT_PROPAGATE
}
sub do_quit {
  Gtk2->main_quit;
}
$builder->connect_signals;

my $toplevel = $builder->get_object('toplevel');
$toplevel->show_all;
Gtk2->main;
exit 0;
