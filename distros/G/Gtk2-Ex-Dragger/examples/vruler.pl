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


# This bit of nonsense sets up a Gtk2::VRuler to be driven by a
# Gtk2::Adjustment, then a dragger to move the adjustment and hence the
# ruler.
#
# The ruler widgets are a bit freaky, they probably seemed like a good idea
# to someone making a print previewer, but beyond that you're probably not
# going to use them.  As an example though this shows how a widget like a
# ruler that doesn't normally work from an adjustment might be linked up and
# then moved with Gtk2::Ex::Dragger.
#
#
# The triangular "position" marker in the ruler is left to follow the mouse
# of its own accord, in the usual way it does for a ruler.  Whether that's a
# good thing is another matter, but you can't force it -- if you change the
# "position" setting it only fights with the next motion event the ruler
# sees.
#

use 5.008;
use strict;
use warnings;
use Gtk2 1.220 '-init';
use Gtk2::Ex::Dragger;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $ruler = Gtk2::VRuler->new;
$toplevel->add ($ruler);

# septics, eh ... not only do they refuse to use metric but they misspell
# the names of the units ...
$ruler->set_metric ('centimeters');

use constant PAGE_SIZE => 200.0;
my $adj = Gtk2::Adjustment->new (0.0,              # value
                                 -5 * PAGE_SIZE,   # lower
                                 5 * PAGE_SIZE,    # upper
                                 0.1 * PAGE_SIZE,  # step incr
                                 0.8 * PAGE_SIZE,  # page incr
                                 PAGE_SIZE);       # page size

sub ruler_from_adj {
  $ruler->set (lower => $adj->value,
               upper => $adj->value + $adj->page_size);
}
ruler_from_adj(); # initial setting
$adj->signal_connect (value_changed => \&ruler_from_adj);

# size 30mm wide by 150mm high
my $screen = $ruler->get_screen;
$toplevel->set_size_request
  (30 * $screen->get_width / $screen->get_width_mm,
   150 * $screen->get_height / $screen->get_height_mm);

my $dragger = Gtk2::Ex::Dragger->new
  (widget      => $ruler,
   vadjustment => $adj);

$ruler->signal_connect (button_press_event => sub {
                          my ($ruler, $event) = @_;
                          if ($event->button == 1) {
                            $dragger->start ($event);
                          }
                          return Gtk2::EVENT_PROPAGATE;
                        });

$toplevel->show_all;
Gtk2->main();
exit 0;
