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


# Usage: ./order.pl
#
# This program illustrates the way pack_start and pack_end interoperate.
# Packing like this is a standard thing for any widget implementing
# GtkCellLayout, and it's the same as pack_start/pack_end in a GtkBox.
#
# Basically within each model item the pack_start renderers are drawn from
# the left and then the pack_end renderers from the right.  TickerView
# doesn't leave any space in the middle, so it ends up being the starts
# drawn in order then the ends drawn in reverse order (ie. going from the
# right).  Thus the renderers below (which ignore the data in the model),
# get added as "starts" 1, 2, 3 then "ends" 4, 5, 6, and give "1 2 3 6 5 4".

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::TickerView;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });
$toplevel->set_size_request (300, -1);

my $liststore = Gtk2::ListStore->new ('Glib::String');
$liststore->set ($liststore->append, 0, 'dummy');

my $ticker = Gtk2::Ex::TickerView->new (model => $liststore);
$toplevel->add ($ticker);

{ my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (text => ' ... ');
  $ticker->pack_start ($renderer, 0);
}
{ my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (text => ' 1 ');
  $ticker->pack_start ($renderer, 0);
}
{ my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (text => ' 2 ');
  $ticker->pack_start ($renderer, 0);
}
{ my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (text => ' 3 ');
  $ticker->pack_start ($renderer, 0);
}
{ my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (text => ' 4 ');
  $ticker->pack_end ($renderer, 0);
}
{ my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (text => ' 5 ');
  $ticker->pack_end ($renderer, 0);
}
{ my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (text => ' 6 ');
  $ticker->pack_end ($renderer, 0);
}


$toplevel->show_all;
Gtk2->main;
exit 0;
