#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;

BEGIN { $ENV{'DISPLAY'} ||= ':0' }
use Gtk2 '-init';
use Gtk2::Ex::Statusbar::MessageUntilKey;

use FindBin;
my $progname = $FindBin::Script;

my $display1 = Gtk2::Gdk::Display->get_default;
say $display1;
my $display_name = $display1->get_name;
say $display_name;
my $display2 = Gtk2::Gdk::Display->open ($display_name);
say $display2;

my @displays = ($display1, $display2);
my @toplevels;
my @vboxes;

foreach my $i (0 .. 1) {
  my $display = $displays[$i];
  my $screen = $display->get_default_screen;
  say $screen;

  my $toplevel = Gtk2::Window->new ('toplevel');
  push @toplevels, $toplevel;
  $toplevel->set_screen ($screen);
  $toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

  my $vbox = Gtk2::VBox->new;
  push @vboxes, $vbox;
  $toplevel->add($vbox);

  my $drawingarea = Gtk2::DrawingArea->new;
  $drawingarea->set_size_request (200, 20);
  $drawingarea->add_events ('button-press-mask');
  $vbox->add ($drawingarea);

  my $statusbar = Gtk2::Statusbar->new;

  {
    my $button = Gtk2::Button->new_with_mnemonic ('_Message                 ');
    $vbox->add ($button);
    $button->signal_connect
      (clicked => sub {
         print "$progname: show message\n";
         Gtk2::Ex::Statusbar::MessageUntilKey->message($statusbar, 'Hello World');
       });
  }
  {
    my $button = Gtk2::Button->new_with_mnemonic ('_Remove');
    $vbox->add ($button);
    $button->signal_connect
      (clicked => sub {
         print "$progname: unparent\n";
         $vbox->remove($statusbar);
       });
  }
  {
    my $button = Gtk2::Button->new_with_mnemonic ('_To Other');
    $vbox->add ($button);
    $button->signal_connect
      (clicked => sub {
         print "$progname: to other\n";
         Gtk2::Ex::Statusbar::MessageUntilKey->message($statusbar, 'To Other');
         $vbox->remove($statusbar);
         $vboxes[$i ^ 1]->add ($statusbar);
       });
  }

  $vbox->add ($statusbar);

  $toplevel->show_all;
}

Gtk2->main;
exit 0;
