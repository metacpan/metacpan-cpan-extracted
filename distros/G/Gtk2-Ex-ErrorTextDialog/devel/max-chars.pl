#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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
use Gtk2 '-init';
use Gtk2::Ex::ErrorTextDialog;

use FindBin;
use lib::abs $FindBin::Bin;
my $progname = $FindBin::Script;

print "$progname: MessageDialog has 'text': ",
  Gtk2::MessageDialog->find_property('text')?"yes":"no","\n";

Gtk2::Ex::ErrorTextDialog->instance->set(max_chars => 200);
Gtk2::Ex::ErrorTextDialog->instance->present;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub {
                             print "$progname: quit\n";
                             Gtk2->main_quit;
                           });

my $vbox = Gtk2::VBox->new (0, 0);
$toplevel->add ($vbox);

# Gtk2::Ex::ErrorTextDialog->popup;

{
  my $button = Gtk2::Button->new_with_label ("add_message()");
  $vbox->pack_start ($button, 0,0,0);
  my $count = 0;
  $button->signal_connect
    (clicked => sub {
       print "$progname: add_message()\n";
       $count++;
       Gtk2::Ex::ErrorTextDialog->add_message
           ("hello this is a line of text $count\n");
       my $errtext = Gtk2::Ex::ErrorTextDialog->instance;
       my $textbuf = $errtext->{'textbuf'};
       print "$progname: char_count ",$textbuf->get_char_count,"\n";
     });
}

{
  my $button = Gtk2::Button->new_with_label ("big add_message()");
  $button->signal_connect
    (clicked => sub {
       print "$progname: big add_message()\n";
       Gtk2::Ex::ErrorTextDialog->popup_add_message
           (join ("\n", 1 .. 50));
       my $errtext = Gtk2::Ex::ErrorTextDialog->instance;
       my $textbuf = $errtext->{'textbuf'};
       print "$progname: char_count ",$textbuf->get_char_count,"\n";
     });
  $vbox->pack_start ($button, 0,0,0);
}

$toplevel->show_all;
Gtk2->main;
exit 0;
