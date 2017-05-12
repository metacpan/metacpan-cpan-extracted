#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-QuadButton.
#
# Gtk2-Ex-QuadButton is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-QuadButton is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-QuadButton.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Glib::Ex::ConnectProperties;
use Gtk2::Ex::QuadScroll;
use Gtk2::Ex::DirButton;

use FindBin;
my $progname = $FindBin::Script;

# uncomment this to run the ### lines
use Smart::Comments;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $qb = Gtk2::Ex::DirButton->new
  ();
$qb->signal_connect (clicked => sub {
                             print "$progname: change-value @_\n";
                             if (my $hadj = $qb->{'hadjustment'}) {
                               print "  hadj ",$hadj->value,"\n";
                             }
                             if (my $vadj = $qb->{'vadjustment'}) {
                               print "  vadj ",$vadj->value,"\n";
                             }
                           });
$vbox->pack_start ($qb, 1,1,0);
# $qb->set_size_request (100, 100);

# {
#   my $button = Gtk2::CheckButton->new_with_label ('Sensitive');
#   Glib::Ex::ConnectProperties->new
#       ([$qb, 'sensitive'],
#        [$button, 'active']);
#   $vbox->pack_start ($button, 0, 0, 0);
# }

$toplevel->show_all;

### normal: $qb->style->fg('normal')->to_string
### prelight: $qb->style->fg('prelight')->to_string
### active: $qb->style->fg('active')->to_string
### selected: $qb->style->fg('selected')->to_string
### insensitive: $qb->style->fg('insensitive')->to_string

### normal: $qb->style->bg('normal')->to_string
### prelight: $qb->style->bg('prelight')->to_string
### active: $qb->style->bg('active')->to_string
### selected: $qb->style->bg('selected')->to_string
### insensitive: $qb->style->bg('insensitive')->to_string

Gtk2->main;
exit 0;
