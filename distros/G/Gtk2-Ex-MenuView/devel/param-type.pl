#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-MenuView.
#
# Gtk2-Ex-MenuView is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-MenuView is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-MenuView.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::MenuView;
use Data::Dumper;

my $menuview = Gtk2::Ex::MenuView->new;
# $menuview->set (item_type => 'Gtk2::MenuItem');

my $info = $menuview->find_property ('model');
print Dumper($info);

# my $info = $menuview->find_property ('label-column');
# print Dumper($info);
# 
# my $info = $menuview->find_property ('item_type');
# print Dumper($info);
