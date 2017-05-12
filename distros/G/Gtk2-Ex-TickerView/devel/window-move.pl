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


# Usage: ./window-move.pl
#
# This program moves or resizes a tickerview to see the effect on dragging.
# As from TickerView version 7 the contents go with the window and the mouse
# drags relative to their new position.
#

use strict;
use warnings;
use Gtk2 '-init';

use Gtk2::Ex::TickerView;


my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $hbox = Gtk2::HBox->new (0, 0);
$toplevel->add ($hbox);

my $left_vbox = Gtk2::VBox->new (0, 0);
$hbox->pack_start ($left_vbox, 0,0,0);

my $right_vbox = Gtk2::VBox->new (0, 0);
$hbox->pack_start ($right_vbox, 1,1,0);

my $ticker_width = 400;

my $layout = Gtk2::Layout->new;
$layout->set_size_request ($ticker_width + 100, 100);
$layout->modify_fg ('normal', Gtk2::Gdk::Color->parse ('white'));
$layout->modify_bg ('normal', Gtk2::Gdk::Color->parse ('black'));
$right_vbox->pack_start ($layout, 1,1,0);

my $model = Gtk2::ListStore->new ('Glib::String');
foreach my $str ('yy', 'zz-bb', '<b>xx</b>', 'fjdks', '32492', "abc\ndef") {
  my $iter = $model->append;
  $model->set_value ($iter, 0, $str);
}

my $ticker = Gtk2::Ex::TickerView->new (model => $model,
                                        run => 0);
$ticker->set_size_request ($ticker_width, -1);
$layout->add ($ticker);

my $renderer = Gtk2::CellRendererText->new;
$ticker->pack_start ($renderer, 1);
$ticker->set_attributes ($renderer, text => 0);


{
  my $timer_id;
  my $idx = 0;
  my @widths = (400, 350, 300, 350);
  my $button = Gtk2::CheckButton->new_with_label ('Resizing');
  $button->set_tooltip_markup
    ("Check this to resize the DrawingArea under a timer, to test lasso recalc when some of it goes outside the new size");
  $left_vbox->pack_start ($button, 0,0,0);
  $button->signal_connect ('toggled' => sub {
                             if ($button->get_active) {
                               $timer_id ||= do {
                                 print __FILE__,": resizing start\n";
                                 Glib::Timeout->add (1000, \&resizing_timer);
                               };
                             } else {
                               if ($timer_id) {
                                 print __FILE__,": resizing stop\n";
                                 Glib::Source->remove ($timer_id);
                                 $timer_id = undef;
                               }
                             }
                           });
  sub resizing_timer {
    $idx++;
    if ($idx >= @widths) {
      $idx = 0;
    }
    my $width = $widths[$idx];
    print __FILE__,": resize to $width\n";
    $ticker->set_size_request ($width, -1);
    return 1; # keep running
  }
}
{
  my $timer_id;
  my $idx = 0;
  my @x = (0, 50, 100, 50);
  my $button = Gtk2::CheckButton->new_with_label ('Repositioning');
  $button->set_tooltip_markup
    ("Check this to resize the DrawingArea under a timer, to test lasso recalc when some of it goes outside the new size");
  $left_vbox->pack_start ($button, 0,0,0);
  $button->signal_connect ('toggled' => sub {
                             if ($button->get_active) {
                               $timer_id ||= do {
                                 print __FILE__,": repositioning start\n";
                                 Glib::Timeout->add (1000, \&repositioning_timer);
                               };
                             } else {
                               if ($timer_id) {
                                 print __FILE__,": repositioning stop\n";
                                 Glib::Source->remove ($timer_id);
                                 $timer_id = undef;
                               }
                             }
                           });
  sub repositioning_timer {
    $idx++;
    if ($idx >= @x) {
      $idx = 0;
    }
    my $x = $x[$idx];
    print __FILE__,": reposition to $x,0\n";
    $layout->move ($ticker, $x, 0);
    return 1; # keep running
  }
}
{
  my $button = Gtk2::CheckButton->new_with_label ('DebugUps');
  $button->set_tooltip_markup ("Set Gtk2::Gdk::Window->set_debug_updates to flash invalidated regions");
  $button->set_active (0);
  $button->signal_connect (toggled => sub {
                             Gtk2::Gdk::Window->set_debug_updates
                                 ($button->get_active);
                           });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Quit');
  $button->signal_connect (clicked => sub { $toplevel->destroy; });
  $left_vbox->pack_start ($button, 0, 0, 0);
}


$toplevel->show_all;
Gtk2->main;
exit 0;
