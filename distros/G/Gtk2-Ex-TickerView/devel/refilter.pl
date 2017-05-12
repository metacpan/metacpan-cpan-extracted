#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TickerView.
#
# Gtk2-Ex-TickerView is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-TickerView is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TickerView.  If not, see <http://www.gnu.org/licenses/>.


use Gtk2;
use strict;
use warnings;

my $store = Gtk2::ListStore->new ('Glib::Int');
$store->set ($store->insert(0), 0=>100);
$store->set ($store->insert(1), 0=>110);
$store->set ($store->insert(2), 0=>120);
$store->set ($store->insert(3), 0=>130);

my $filter = Gtk2::TreeModelFilter->new ($store);

$filter->signal_connect (row_deleted => sub {
                           my ($model, $del_path) = @_;
                           my ($del_index) = $del_path->get_indices;
                           print "row-deleted $del_index\n";
                         });
my $recurse = 1;
$filter->signal_connect (row_inserted => sub {
                           my ($model, $ins_path) = @_;
                           if ($recurse) {
                             $recurse = 0;
                             print "recurse further insert\n";
                             $store->set ($store->insert(4), 0=>140);
                           }
                         });
$filter->signal_connect (row_inserted => sub {
                           my ($model, $ins_path) = @_;
                           my ($ins_index) = $ins_path->get_indices;
                           my $len = $model->iter_n_children(undef);
                           print "row-inserted index=$ins_index, len=$len\n";

                           if ($recurse && $ins_index == 0) {
                             $recurse = 0;
                             print " recurse further insert\n";
                             $store->set ($store->insert(4), 0=>140);
                           }
                         });
my %visible = (0 => 1,
               1 => 0,
               2 => 0,
               3 => 1,
               4 => 1);
$filter->set_visible_func
  (sub { my ($child_model, $child_iter) = @_;
         my $path = $child_model->get_path($child_iter);
         my ($index) = $path->get_indices;
         print "visible $index => $visible{$index}\n";
         return $visible{$index};
       });

print "refilter\n";
$filter->refilter;

%visible = (0 => 1,
            1 => 1,
            2 => 0,
            3 => 0);
print "\nrefilter again\n";
$filter->refilter;
exit 0;
