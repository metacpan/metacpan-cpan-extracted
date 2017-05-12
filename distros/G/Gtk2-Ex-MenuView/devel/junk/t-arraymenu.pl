#!/usr/bin/perl

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
use Data::Dumper;
use Gtk2 '-init';
use Gtk2::Ex::ArrayMenu;

sub my_activate {
  print Dumper (\@_);
  print join(',', @_), "\n";
}

sub my_name {
  my ($arraymenu, $str) = @_;
  return 'x' . $str . 'z';
}

my $menu = Gtk2::Ex::ArrayMenu->new (array => ['<s>AA</s>',
                                               'B_BB',
                                               'C_C'],
                                     name_proc => \&my_name,
                                     use_mnemonic => 1,
                                    );
$menu->signal_connect (activate => \&my_activate);
$menu->show;

$menu->popup (undef, undef, undef, undef, 0, 0);
Gtk2->main();
exit 0;
