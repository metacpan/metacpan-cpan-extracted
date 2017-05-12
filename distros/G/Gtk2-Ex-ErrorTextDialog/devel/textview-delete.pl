#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-ErrorTextDialog.
#
# Gtk2-Ex-ErrorTextDialog is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ErrorTextDialog is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ErrorTextDialog.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Data::Dumper;
use Gtk2 '-init';
use Gtk2::Ex::TextView::FollowAppend;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->set_default_size (200, 300);
$toplevel->signal_connect (destroy => sub {
                             print "$progname: quit\n";
                             Gtk2->main_quit;
                           });

my $vbox = Gtk2::VBox->new (0, 0);
$toplevel->add ($vbox);

my $scrolled = Gtk2::ScrolledWindow->new;
$scrolled->set_policy ('automatic', 'always');
$vbox->add ($scrolled);

my $textbuf = Gtk2::TextBuffer->new();
my $textview = Gtk2::TextView->new_with_buffer ($textbuf);
$scrolled->add ($textview);

$textbuf->insert ($textbuf->get_end_iter,
                  join ('', map { "hello $_\n" } 0 .. 25));

{
  my $button = Gtk2::Button->new_with_label ("delete from start");
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect
    (clicked => sub {
       print "$progname: delete\n";
       $textbuf->delete ($textbuf->get_start_iter,
                         $textbuf->get_iter_at_line(3));
     });
}

$toplevel->show_all;
Gtk2->main;
exit 0;
