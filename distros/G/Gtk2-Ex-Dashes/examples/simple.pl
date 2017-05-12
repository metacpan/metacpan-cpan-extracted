#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Dashes.
#
# Gtk2-Ex-Dashes is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Dashes is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Dashes.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Gtk2 '-init';

use Gtk2::Ex::Dashes;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (200, 50);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $dashes = Gtk2::Ex::Dashes->new;
$toplevel->add ($dashes);

$toplevel->show_all;
Gtk2->main;
exit 0;
