#!/usr/bin/perl -w

# Copyright 2007, 2008, 2010 Kevin Ryde

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


# Usage: ./simple.pl
#
# This program is pretty much the minimum you need to do to get something
# showing on the screen for a TickerView, or any of the Gtk model/view
# things for that matter.  Basically a model supplies the data, then a
# CellRenderer is how to draw it, and the "attributes" settings on the
# TickerView tie the model's data columns to the renderer's input
# properties.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::TickerView;

# Create a model object with the data that's going to be shown, in this case
# a Gtk2::ListStore with just one column and just text strings in the rows.
# The "*"s at the start of each item are a simple visual separator.  You
# could use a unicode bullet or the like if you're confident of having the
# fonts.
#
my $liststore = Gtk2::ListStore->new ('Glib::String');
foreach my $str ('* Item one',
                 '* Item two',
                 '* Item three',
                 '* Item four',
                 '* Item five') {
  $liststore->set_value ($liststore->append,  # append new row
                         0,                   # store to column 0
                         $str);               # store this string
}

# Now the TickerView itself, giving it the model just created.
# You could have multiple tickers all displaying the same underlying model,
# if that made sense.
#
my $ticker = Gtk2::Ex::TickerView->new (model => $liststore);

# But the TickerView by itself doesn't draw anything, that has to be done
# with a CellRenderer set into it, in this case a text renderer.
#
my $cellrenderer = Gtk2::CellRendererText->new;
$ticker->pack_start ($cellrenderer, 0);

# And the TickerView has to be told what data columns to pass from the model
# into the CellRenderer.  In this case there's just one text string column
# in the model (column 0) and it's the text for the renderer.  But you could
# also have another column as say 'foreground' for per-item colour control
# (something incidentally which can also be done through a Pango markup
# string from the model and passing that as 'markup' instead of 'text' into
# the CellRenderer).
#
$ticker->add_attribute ($cellrenderer,
                        'text', # the renderer setting
                        0);     # and the column of the model


# Now stick the TickerView in a toplevel window.
#
my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });
$toplevel->add ($ticker);

# The TickerView will give a desired height, so -1 meaning "natural" height
# here lets that pass upwards.  But the TickerView doesn't have any
# particular desired width, so guess at 300 pixels.  You could do something
# based on the screen width, or on the width of a character in the
# CellRenderer's font etc if you wanted to be fancy.
#
$toplevel->set_size_request (300, -1);


$toplevel->show_all;
Gtk2->main;
exit 0;
