#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

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


# This is example of using Gtk2::Builder to create a lasso.  The type name
# is "Gtk2__Ex__Lasso" as usual for Perl-Gtk class name to GType name
# mapping.
#
# The lasso object is a separate toplevel and the "widget" property sets
# where it will select and draw.  Starting the lasso must be done from code
# in a signal handler, getting the lasso object out of the builder.
#
# The "foreground-name" property on the lasso can set the lasso colour.  The
# plain "foreground" property is a Glib::Scalar which can't be set from
# builder xml (as of Perl-Gtk 1.240).  "foreground-gdk" also works, and
# verifies the colour name is known, but it allocates the colour in the
# default colormap, which is unnecessary.
#

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::Lasso;
use Data::Dumper;

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
          <object class="GtkLabel" id="label">
            <property name="xpad">10</property>
            <property name="label">
Lassoing with GtkBuilder.
  Button 1 - press and drag to lasso.
  Esc - abort.
  Space - swap ends.
</property>
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

  <object class="Gtk2__Ex__Lasso" id="lasso">
    <property name="widget">toplevel</property>
    <property name="foreground-name">red</property>
    <signal name="ended" handler="do_ended"/>
  </object>
</interface>
HERE

sub do_button_press {
  my ($toplevel, $event) = @_;
  if ($event->button == 1) {
    my $lasso = $builder->get_object('lasso');
    $lasso->start ($event);
    print "Lasso started\n";
  }
  return 0; # Gtk2::EVENT_PROPAGATE
}
sub do_ended {
  my ($lasso, $x1,$y1, $x2,$y2) = @_;
  print "Lasso area $x1,$y1 to $x2,$y2\n";
}
sub do_quit {
  Gtk2->main_quit;
}

$builder->connect_signals;

my $toplevel = $builder->get_object('toplevel');
$toplevel->show_all;
Gtk2->main;
exit 0;
