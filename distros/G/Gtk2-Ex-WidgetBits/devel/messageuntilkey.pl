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
use Gtk2::Ex::Statusbar::MessageUntilKey;

use FindBin;
my $progname = $FindBin::Script;

{
  $ENV{'DISPLAY'} ||= ':0';
  require Gtk2;
  Gtk2->init;

  my $toplevel = Gtk2::Window->new ('toplevel');
  $toplevel->signal_connect (destroy => sub { Gtk2->main_quit });
  $toplevel->add_events ('button-press-mask');

  my $vbox = Gtk2::VBox->new;
  $toplevel->add($vbox);

  my $drawingarea = Gtk2::DrawingArea->new;
  $drawingarea->set_size_request (200, 20);
  $drawingarea->add_events ('button-press-mask');
  $vbox->add ($drawingarea);

  my $button = Gtk2::Button->new_with_mnemonic ('_Message                 ');
  $vbox->add ($button);

  my $statusbar = Gtk2::Statusbar->new;
  $vbox->add ($statusbar);

  $button->signal_connect
    (clicked => sub {
       print "$progname: show message\n";
       Gtk2::Ex::Statusbar::MessageUntilKey->message($statusbar, 'Hello World');
     });

  $toplevel->show_all;
  Gtk2->main;
  exit 0;
}

{
  $ENV{'DISPLAY'} ||= ':0';
  require Gtk2;
  Gtk2->init;

  my $statusbar = Gtk2::Statusbar->new;
  say "display ", $statusbar->get_display // 'undef';

  my $display = Gtk2::Gdk::Display->open ($ENV{'DISPLAY'});
  my $screen = $display->get_default_screen;

  my $toplevel = Gtk2::Window->new ('toplevel');
  $toplevel->set_screen ($screen);
  $toplevel->add($statusbar);
  say "display ", $statusbar->get_display // 'undef';

  $statusbar->unparent;
  say "display ", $statusbar->get_display // 'undef';

  exit 0;
}

