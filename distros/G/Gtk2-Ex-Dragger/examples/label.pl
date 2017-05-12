#!/usr/bin/perl -w

# Copyright 2008, 2010, 2011 Kevin Ryde

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


# This example scrolls a Gtk2::Viewport containing a label.  A Viewport like
# this is the usual way to add scrollability to widgets without their own
# notion of a scrolled position.
#
# Notice the dragger is set on the viewport, not the contained label.  It's
# the viewport which is the visible part corresponding to the adjustment
# page, and responding to the adjustment "value" position.
#
# If you think the scrolling in this example isn't as smooth as in
# textview.pl, well, you're right.  GtkTextView is much more efficient at
# drawing than GtkLabel.  Probably that's fair enough, since a Label is
# normally static, as opposed to TextView designed for editing and moving
# around.  If you want to see how bad the Label gets then try the
# commented-out "update_policy => 'continuous'" in the
# Gtk2::Ex::Dragger->new() call below.  Unless you've got a fast computer
# and fast video card you'll be disappointed by how much the label drawing
# lags the mouse movement.
#

use 5.008;
use strict;
use warnings;
use Gtk2 1.220 '-init';
use Gtk2::Ex::Dragger;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });
$toplevel->set_default_size (300, 300);

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $heading = Gtk2::Label->new ('Drag with mouse button 1');
$vbox->pack_start ($heading, 0,0,5);

my $scrolled = Gtk2::ScrolledWindow->new;
$scrolled->set (hscrollbar_policy => 'always',
                vscrollbar_policy => 'always');
$vbox->pack_start ($scrolled, 1,1,0);

my $viewport = Gtk2::Viewport->new;
$scrolled->add ($viewport);

my $label = Gtk2::Label->new;
$viewport->add ($label);

# some random text in the label
my $line = join(',    ', 1..18) . "\n";
my $str = $line x 40;
$label->set_text ($str);

my $dragger = Gtk2::Ex::Dragger->new
  (widget      => $viewport,
   hadjustment => $viewport->get_hadjustment,
   vadjustment => $viewport->get_vadjustment,
   # update_policy => 'continuous',
  );

$viewport->signal_connect
  (button_press_event => sub {
     my ($viewport, $event) = @_;
     if ($event->button == 1) {
       print __FILE__.": start drag\n";
       $dragger->start ($event);
       return Gtk2::EVENT_STOP;
     } else {
       return Gtk2::EVENT_PROPAGATE;
     }
   });

$toplevel->show_all;
Gtk2->main;
exit 0;
