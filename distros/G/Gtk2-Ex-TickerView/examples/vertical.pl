#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

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


# Usage: ./vertical.pl
#
# This is a sample vertical scrolling ticker.  The only real difference from
# the other programs is "orientation => 'vertical'" in the ticker.
#
# The data shown is some "stock" item icons.  Gtk2::CellRendererPixbuf takes
# a stock ID string ('gtk-ok' etc) and does the real work.
#
# If you're scrolling text vertically you normally want it upright, as shown
# here for the icon names.  But if you want to get creative and show
# something rotated 90 degrees you may have to do your own cell renderer.
# As of gtk 2.12 the plain CellRendererText doesn't seem to have a rotation
# setting nor does it follow a pango "gravity" attribute set in text markup
# or the 'attributes' property.  (Have a nose around the GtkLabel sources
# for making a pango transform matrix to apply before getting the size or
# drawing.)
#
# Oh, and if vertical mode puts you in mind of the way television news has a
# line of text for a news item which scrolls up to the next, well, alas the
# TickerView isn't really setup to pause at each item.  Some manipulation of
# the 'run' property or some direct scroll_pixels() might get close, but if
# you only wanted to see one row at a time you might be inclined to make a
# new type of widget doing only that.
#

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::TickerView;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });
$toplevel->set_size_request (-1, 300);

# You could use Gtk2::Stock->list_ids() here to see all stock items, but if
# you don't have the "hicolor" icon theme stuff installed then it might
# print warnings about unavailable images each time the ticker tries to draw
# those.
#
my $liststore = Gtk2::ListStore->new ('Glib::String');
foreach my $stock_id (qw (gtk-about
                          gtk-apply
                          gtk-cancel
                          gtk-cdrom
                          gtk-copy
                          gtk-cut
                          gtk-delete
                          gtk-edit
                          gtk-file
                          gtk-help
                          gtk-home
                          gtk-info
                          gtk-italic
                          gtk-new
                          gtk-no
                          gtk-ok
                          gtk-open
                          gtk-paste
                          gtk-print
                          gtk-quit
                          gtk-refresh
                          gtk-save
                          gtk-stop
                          gtk-yes
                          gtk-zoom-in
                          gtk-zoom-out
                        )) {
  $liststore->set_value ($liststore->append, 0 => $stock_id);
}

my $ticker = Gtk2::Ex::TickerView->new (model => $liststore,
                                        orientation => 'vertical',
                                        run => 1);
$toplevel->add ($ticker);

my $text_renderer = Gtk2::CellRendererText->new;
$ticker->pack_start ($text_renderer, 0);
$ticker->add_attribute ($text_renderer, text => 0);

my $pixbuf_renderer = Gtk2::CellRendererPixbuf->new;
$pixbuf_renderer->set (xpad => 4, ypad => 4);
$ticker->pack_start ($pixbuf_renderer, 0);
$ticker->add_attribute ($pixbuf_renderer, icon_name => 0);

$toplevel->show_all;
Gtk2->main;
exit 0;
