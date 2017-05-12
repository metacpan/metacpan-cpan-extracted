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


# Usage: perl builder-internal.pl
#
# This is a variation on builder.pl showing how to use a class which offers
# its adjustments as "internal-child" objects in the builder.
#
# None of the builtin Gtk widgets do this natively (as of Gtk 2.20), hence a
# few lines of MyViewport extending the basic Gtk2::Viewport with internal
# children "hadjustment" and "vadjustment".
#
# The operative part is the <child internal-child="hadjustment"> bits which
# is how you apply an id="whatever" to the respective child and which you
# can then use as the property value for the dragger.
#
# It's not a huge improvement over creating your own adjustment objects like
# in the plain builder.pl, but if you're making a draggable widget or
# container with adjustments then consider offering the default ones through
# the buildable interface "internal-child" so they can be referred to by a
# dragger or similar.
#

use 5.008;
use strict;
use warnings;
use Gtk2 1.220;
use Gtk2 '-init';
use Gtk2::Ex::Dragger;

# uncomment this to run the ### lines
#use Smart::Comments;

{
  package MyViewport;
  use Glib::Object::Subclass 'Gtk2::Viewport',
    interfaces => [ 'Gtk2::Buildable' ];
  sub ADD_CHILD {
    ### ADD_CHILD: @_
    my ($self, $builder, $child) = @_;
    $self->add ($child);
  }
  sub GET_INTERNAL_CHILD {
    my ($self, $builder, $childname) = @_;
    ### GET_INTERNAL_CHILD: $childname
    ### give: $self->get($childname)
    return $self->get($childname);
  }
}

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<"HERE");
<interface>
  <object class="GtkWindow" id="toplevel">
    <property name="type">toplevel</property>
    <property name="border-width">10</property>
    <property name="width-request">150</property>
    <property name="height-request">150</property>
    <signal name="destroy" handler="do_quit"/>

    <child>
      <object class="MyViewport" id="viewport">
        <property name="border-width">0</property>

        <child internal-child="hadjustment">
          <object class="GtkAdjustment" id="hadj"/>
        </child>
        <child internal-child="vadjustment">
          <object class="GtkAdjustment" id="vadj"/>
        </child>

        <child>
          <object class="GtkLabel" id="label">
            <property name="label">2   222   111   333   333   111   111
 666   333   222   111   222   333   333
 666   333   222   111   222   333   333
 666   333   222   111   222   333   333
2   222   333   222   444   666   111
2   222   333   222   444   666   111
2   222   333   222   444   666   111
 555   111   222   444   222   333   444
 555   111   222   444   222   333   444
 555   111   222   444   222   333   444
1   555   444   111   222   222   222
1   555   444   111   222   222   222
1   555   444   111   222   222   222
 111   111   333   222   222   222   111
 111   111   333   222   222   222   111
 111   111   333   222   222   222   111
2   333   111   111   111   111   555
2   333   111   111   111   111   555
2   333   111   111   111   111   555
 111   333   222   111   111   333   111
 111   333   222   111   111   333   111
 111   333   222   111   111   333   111
3   222   111   333   222   222   111
3   222   111   333   222   222   111
3   222   111   333   222   222   111
 222   111   444   222   222   333   333
 222   111   444   222   222   333   333
 222   111   444   222   222   333   333
1   555   222   333   222   333   111
1   555   222   333   222   333   111
1   555   222   333   222   333   111
 222   111   444   222   222   222   444
 222   111   444   222   222   222   444
 222   111   444   222   222   222   444
3   444   111   777   222   333   111
3   444   111   777   222   333   111
3   444   111   777   222   333   111
 222   111   555   111   333   222   444
 222   111   555   111   333   222   444
 222   111   555   111   333   222   444
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
    <property name="hadjustment">hadj</property>
    <property name="vadjustment">vadj</property>
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
