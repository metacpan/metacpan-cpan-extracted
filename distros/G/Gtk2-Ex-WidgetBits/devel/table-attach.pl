#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::WidgetBits;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });
$toplevel->set_default_size (-1, 300);

my $table = Gtk2::Table->new (1, 6, 0);
$toplevel->add ($table);

my $label = Gtk2::Label->new ("hello");
$label->signal_connect
  (child_notify => sub {
     my (undef, $height) = $toplevel->get_size;
     print "child-notify: top ", $table->child_get_property ($label, 'top_attach'), "\n";
     print "           bottom ", $table->child_get_property ($label, 'bottom_attach'), "\n";
   });

my $l2 = Gtk2::Label->new ("world");

my $spin = Gtk2::SpinButton->new_with_range (0, 999, 1);
my $adj = $spin->get_adjustment;
$adj->set (value => 3);
$adj->signal_connect
  (value_changed => sub {
     my (undef, $height) = $toplevel->get_size;
     # $table->child_set_property ($label, y_padding => $adj->value);
     $table->child_set_property ($label, bottom_attach => $adj->value);
     print "top ", $table->child_get_property ($label, 'top_attach'), "\n";
     print "bottom ", $table->child_get_property ($label, 'bottom_attach'), "\n";
   });

$table->attach ($spin,  0,1, 0,1, [], [], 0, 0);
$table->attach ($l2,    0,1, 1,2, [], ['fill','expand'], 0, 0);
$table->attach ($label, 0,1, 2,3, [], ['fill','expand'], 0, 0);

$toplevel->show_all;
Gtk2->main;
exit 0;
