#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-CellLayout-Base.
#
# Gtk2-Ex-CellLayout-Base is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-CellLayout-Base is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-CellLayout-Base.  If not, see <http://www.gnu.org/licenses/>.


# How CellView packs from start and end.


use strict;
use warnings;
use Gtk2 '-init';

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $cellview = Gtk2::CellView->new;
$toplevel->add ($cellview);

{ my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (text => ' one ');
  $cellview->pack_start ($renderer, 0);
}
{ my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (text => ' two ');
  $cellview->pack_start ($renderer, 0);
}
{ my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (text => ' three ');
  $cellview->pack_end ($renderer, 0);
}
{ my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (text => ' four ');
  $cellview->pack_end ($renderer, 0);
}

# $cellview->set_size_request (20, -1);

$toplevel->show_all;
Gtk2->main;
exit 0;
