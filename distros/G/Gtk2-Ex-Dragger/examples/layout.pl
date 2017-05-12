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


# This example moves the visible part of a Gtk2::Layout around with a
# Dragger.  It's similar to the Viewport example of heart.pl, but a Layout
# takes fixed child positions and total size in pixels.  Like heart.pl
# there's also no ScrolledWindow or scrollbars shown, since it works
# perfectly well to scroll the Layout around without scrollbars, even if you
# risk not knowing a scroll is possible if you don't have them for visual
# feedback.
#

use 5.008;
use strict;
use warnings;
use Gtk2 1.220 '-init';
use Gtk2::Ex::Dragger;

my $scrollable_width = 300;
my $scrollable_height = 300;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size ($scrollable_width * 0.7,
                             $scrollable_height * 0.7);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $layout = Gtk2::Layout->new;
$toplevel->add ($layout);
$layout->set_size ($scrollable_width, $scrollable_height);

$layout->put (Gtk2::Label->new ('top left'), 0, 0);
{
  my $label = Gtk2::Label->new ('centre');
  my $req = $label->size_request;
  $layout->put ($label,
                ($scrollable_width - $req->width) / 2,
                ($scrollable_height - $req->height) / 2);
}
{
  my $label = Gtk2::Label->new ('top right');
  my $req = $label->size_request;
  $layout->put ($label, $scrollable_width - $req->width, 0);
}
{ my $label = Gtk2::Label->new ('bottom left');
  my $req = $label->size_request;
  $layout->put ($label, 0, $scrollable_height - $req->height);
}
{ my $label = Gtk2::Label->new ('bottom right');
  my $req = $label->size_request;
  $layout->put ($label,
                $scrollable_width - $req->width,
                $scrollable_height - $req->height);
}

my $dragger = Gtk2::Ex::Dragger->new (widget      => $layout,
                                      hadjustment => $layout->get_hadjustment,
                                      vadjustment => $layout->get_vadjustment,
                                      confine     => 1,
                                      cursor      => 'fleur');

$layout->add_events ('button-press-mask');
$layout->signal_connect (button_press_event =>
                         sub {
                           my ($widget, $event) = @_;
                           $dragger->start ($event);
                           return Gtk2::EVENT_PROPAGATE;
                         });

$toplevel->show_all;
Gtk2->main;
exit 0;
