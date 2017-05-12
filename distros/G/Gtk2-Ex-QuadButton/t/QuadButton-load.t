#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-QuadButton.
#
# Gtk2-Ex-QuadButton is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-QuadButton is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-QuadButton.  If not, see <http://www.gnu.org/licenses/>.


## no critic (RequireUseStrict, RequireUseWarnings)
use Gtk2::Ex::QuadButton;
my $qb = Gtk2::Ex::QuadButton->new;

use Test::More tests => 1;
ok (1, 'Gtk2::Ex::QuadButton load as first thing');
exit 0;
