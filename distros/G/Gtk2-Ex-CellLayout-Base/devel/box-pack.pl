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

use strict;
use warnings;
use Gtk2 '-init';

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $hbox = Gtk2::HBox->new (0, 0);
$toplevel->add ($hbox);

$hbox->pack_start (Gtk2::Label->new (' 1 '), 0,0,0);
$hbox->pack_start (Gtk2::Label->new (' 2 '), 0,0,0);

$hbox->pack_end (Gtk2::Label->new (' 3 '), 0,0,0);
$hbox->pack_end (Gtk2::Label->new (' 4 '), 0,0,0);

$toplevel->show_all;
Gtk2->main();
exit 0;
