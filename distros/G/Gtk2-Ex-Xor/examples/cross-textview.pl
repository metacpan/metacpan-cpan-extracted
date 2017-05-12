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


# This example shows putting a CrossHair on a Gtk2::TextView.  This is
# probably a bit unusual.  You hardly need a horizontal guide when
# everything is fixed lines, but a vertical guide might see if columns are
# lining up in a fixed width font.
#
# The CrossHair here is activated with <Alt>-C and de-activated with
# <Alt>-E.  It'd also be possible to look for say <Alt>-Button1 or similar
# with the mouse, but you should use an Alt or Control modifier to avoid
# clashing with the TextView's normal button actions.
#
# The widget X,Y position reported by the CrossHair "moved" callback is
# turned into line/column with the usual TextView functions (in this case
# just printed to stdout).  Some sort of conversion like that is almost
# always needed so you can show a position in user terms not merely pixels.
#

use strict;
use warnings;
use FindBin;
use Gtk2 '-init';
use Gtk2::Ex::CrossHair;
use Data::Dumper;

my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (300, 200);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $scrolled = Gtk2::ScrolledWindow->new;
$toplevel->add ($scrolled);

my $textbuf = Gtk2::TextBuffer->new;
$textbuf->set_text (<<'HERE');
This is some sample text
saying not very much at all really.

Press Alt-C to activate the cross,
press Alt-E to deactivate it.
HERE

my $textview = Gtk2::TextView->new_with_buffer ($textbuf);
$scrolled->add ($textview);

my $cross = Gtk2::Ex::CrossHair->new (widget => $textview,
                                      foreground => 'orange');
$cross->signal_connect (moved => \&cross_moved);
sub cross_moved {
  my ($cross, $widget, $x, $y) = @_;
  if (! defined $x) { return; }  # if outside the window

  my ($buffer_x, $buffer_y)
    = $textview->window_to_buffer_coords ('widget', $x, $y);
  my $iter = $textview->get_iter_at_position ($buffer_x, $buffer_y);
  my $line = $iter->get_line;
  my $column = $iter->get_line_offset;
  print "$progname: cross at $x,$y which is line $line column $column\n";
}

$textview->signal_connect
  (key_press_event =>
   sub {
     my ($widget, $event) = @_;

     if ($event->state >= ['mod1-mask']) {
       if ($event->keyval == Gtk2::Gdk->keyval_from_name('c')) {
         $cross->start ($event);
         return 1; # Gtk2::EVENT_STOP

       } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('e')) {
         $cross->end;
         return 1; # Gtk2::EVENT_STOP
       }
     }
     return 0; # Gtk2::EVENT_PROPAGATE
   });

$toplevel->show_all;
Gtk2->main;
