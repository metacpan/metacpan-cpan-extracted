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

use 5.010;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::MenuView;
use Data::Dumper;

use FindBin;
my $progname = $FindBin::Script;

my $treestore = Gtk2::TreeStore->new ('Glib::String');
foreach my $str ('Item one',
                 'Item two',
                 'Item three',
                 'Item four',
                 'Item five') {
  $treestore->set ($treestore->append(undef), 0 => $str);
}

$treestore->signal_connect (row_deleted => sub {
                              my ($model, $path, $iter) = @_;
                              say "h1: row deleted: ",$path->to_string;
                              $path->append_index(123);
                            });
$treestore->signal_connect (row_deleted => sub {
                              my ($model, $path, $iter) = @_;
                              say "h2: row deleted: ",$path->to_string;
                              $path->append_index(456);
                            });

$treestore->signal_connect
  (row_inserted => sub {
     my ($model, $path, $iter) = @_;
     say "h1: row inserted: ",$path->to_string;
     $treestore->remove ($treestore->get_iter (Gtk2::TreePath->new(0)));
   });
$treestore->signal_connect
  (row_inserted => sub {
     my ($model, $path, $iter) = @_;
     say "h2: row inserted: ",$path->to_string;
   });

$treestore->append(undef);

# $treestore->remove ($treestore->get_iter (Gtk2::TreePath->new(2)));

exit 0;
