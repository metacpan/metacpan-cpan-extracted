#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TickerView.
#
# Gtk2-Ex-TickerView is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-TickerView is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TickerView.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./wrap-width.pl
#
# This example uses the 'wrap-width' property of Gtk2::CellRendererText to
# have text in a vertical ticker wrap around within a fixed ticker width.
#
# Normally, in vertical mode, the TickerView gets a desired width from the
# sizes the renderers want to be.  In this program instead the ticker width
# is forced from the toplevel window size.
#
# The wrap-width property is specific to a text renderer, there's no general
# mechanism for a TickerView (or similar) to tell renderers they should
# limit to a certain width, and then say how much height they'd like to be
# in that width.
#

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::TickerView;

my $store = Gtk2::ListStore->new ('Glib::String');
$store->set ($store->append, 0 => 'Resize using the window manager to see the text wrap within the width you give it.');
$store->set ($store->append, 0 => 'This is the first cell of text.');
$store->set ($store->append, 0 => 'This is another cell of text, longer than the first one.');
$store->set ($store->append, 0 => "And this is the third row of text, and it's yet longer than the first\nAnd it's made up of this second paragraph too.");


my $ticker = Gtk2::Ex::TickerView->new (model => $store,
                                        orientation => 'vertical');
my $renderer = Gtk2::CellRendererText->new;

# horizontal bar between cells, in the text colour
my $gap_renderer = Gtk2::CellRendererPixbuf->new;
$gap_renderer->set_fixed_size (-1, 2);  # height 2 pixels
$gap_renderer->set('cell-background-gdk',$ticker->style->text($ticker->state));

sub size_and_pack_renderer {
  # Must check if size already right, since a clear and pack will provoke a
  # resize request and a further 'size-allocate' signal emission, for an
  # infinite loop.
  #
  # The clear and pack ensures TickerView updates with new cell heights.
  # Viewer widget's don't watch for external changes to renderer properties.
  #
  my $new_wrap_width = $ticker->allocation->width;
  if ($renderer->get('wrap-width') != $new_wrap_width) {
    $ticker->clear;
    $renderer->set('wrap-width', $new_wrap_width);
    $ticker->pack_start ($renderer, 0);
    $ticker->add_attribute ($renderer, text => 0);
    $ticker->pack_start ($gap_renderer, 0);
  }
}
size_and_pack_renderer();
$ticker->signal_connect (size_allocate => \&size_and_pack_renderer);


# Gtk2::Layout container prevents any queue_resize() in the ticker from
# going up to change the toplevel.  Instead the width and height of the
# ticker is set from the size of the toplevel.
#
my $layout = Gtk2::Layout->new;
$layout->signal_connect
  (size_allocate => sub {
     $ticker->set_size_request ($layout->allocation->width,
                                $layout->allocation->height);
   });
$layout->put($ticker, 0, 0);


my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->add ($layout);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });
my ($em, $lineheight) = $ticker->create_pango_layout('M')->get_pixel_size;
$toplevel->set_default_size (15*$em, 15*$lineheight);

$toplevel->show_all;
Gtk2->main;
exit 0;
