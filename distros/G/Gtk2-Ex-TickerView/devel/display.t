#!/usr/bin/perl

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TickerView.
#
# Gtk2-Ex-TickerView is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-TickerView is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TickerView.  If not, see <http://www.gnu.org/licenses/>.


# The timer start and stop tests depend on the windows not being overlapped
# on screen, and on you not being switched away to another virtual terminal,
# so best not have them in the main tests for now.
#
# Some of the drawing tests are probably ok, or could be made so.
#
# 

use strict;
use warnings;
use Gtk2::Ex::TickerView;
use Test::More;

require Gtk2;
diag ("Perl-Gtk2 version ",Gtk2->VERSION);
diag ("Perl-Glib version ",Glib->VERSION);
diag ("Compiled against Glib version ",
      Glib::MAJOR_VERSION(), ".",
      Glib::MINOR_VERSION(), ".",
      Glib::MICRO_VERSION());
diag ("Running on       Glib version ",
      Glib::major_version(), ".",
      Glib::minor_version(), ".",
      Glib::micro_version());
diag ("Compiled against Gtk version ",
      Gtk2::MAJOR_VERSION(), ".",
      Gtk2::MINOR_VERSION(), ".",
      Gtk2::MICRO_VERSION());
diag ("Running on       Gtk version ",
      Gtk2::major_version(), ".",
      Gtk2::minor_version(), ".",
      Gtk2::micro_version());

my $have_display = Gtk2->init_check;
diag "have_display: ",($have_display ? "yes" : "no");

if (! $have_display) {
  plan skip_all => 'due to no DISPLAY available';
}

plan tests => 27;


#------------------------------------------------------------------------------

sub main_sync {
  my ($widget) = @_;
  $widget->get_display->sync;

  my $count = 0;
  while (Gtk2->events_pending) {
    $count++;
    Gtk2->main_iteration_do (0);
  }
  diag "main_sync(): ran $count events/iterations";
}

sub wait_for_event {
  my ($widget, $signame) = @_;
  my $done = 0;
  my $sig_id = $widget->signal_connect ($signame => sub {
                                          $done = 1;
                                          return 0; # Gtk2::EVENT_PROPAGATE
                                        });
  my $timer_id = Glib::Timeout->add (30_000, # 30 seconds
                                     sub {
                                       diag "Oops, timeout on $signame";
                                       exit 1;
                                     });
  $widget->get_display->sync;

  my $count = 0;
  while (! $done) {
    Gtk2->main_iteration;
    $count++;
  }
  while (Gtk2->events_pending) {
    $count++;
    Gtk2->main_iteration_do (0);
  }
  diag "wait_for_event('$signame'): ran $count events/iterations";

  $widget->signal_handler_disconnect ($sig_id);
  Glib::Source->remove ($timer_id);
}


#------------------------------------------------------------------------------
diag "pixmap drawing";

{
  # Resizing stuff in a container probably, maybe, only runs when the
  # container is realized.  Is there a flag directly in the child widget
  # though?
  #
  my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->append, 0 => '111');
  $store->set ($store->append, 0 => '222');
  $store->set ($store->append, 0 => '333');
  $store->set ($store->append, 0 => '444');

  my $ticker = Gtk2::Ex::TickerView->new (model => $store);
  $ticker->set_size_request (30, 10);

  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set_fixed_size (10, 10);
  $ticker->pack_start ($renderer, 0);

  my $toplevel = Gtk2::Window->new ('toplevel');
  $toplevel->add ($ticker);
  $toplevel->show_all;
  wait_for_event ($ticker, 'map_event');

  Gtk2::Ex::TickerView::_pixmap_empty ($ticker);
  Gtk2::Ex::TickerView::_pixmap_extend ($ticker, 30);
  is_deeply ($ticker->{'drawn_array'},
             [ 0,0, 1,10, 2,20 ]);
  is ($ticker->{'pixmap_end_x'}, 30);

  $ticker->{'want_index'} = 0;
  is (Gtk2::Ex::TickerView::_pixmap_find_want ($ticker, 1), 0);

  $ticker->{'want_index'} = 2;
  $ticker->{'want_x'} = -4;
  is (Gtk2::Ex::TickerView::_pixmap_find_want ($ticker, 1), 24);

  Gtk2::Ex::TickerView::_pixmap_shift ($ticker, 3);
  is_deeply ($ticker->{'drawn_array'},
             [ 0,-3, 1,7, 2,17 ]);
  is ($ticker->{'pixmap_end_x'}, 27);

  Gtk2::Ex::TickerView::_pixmap_shift ($ticker, 7);
  is_deeply ($ticker->{'drawn_array'},
             [ 1,0, 2,10 ]);
  is ($ticker->{'pixmap_end_x'}, 20);

  Gtk2::Ex::TickerView::_pixmap_extend ($ticker, 30);
  is_deeply ($ticker->{'drawn_array'},
             [ 1,0, 2,10, 3,20 ]);
  is ($ticker->{'pixmap_end_x'}, 30);

  $toplevel->destroy;
}

#------------------------------------------------------------------------------
diag "get_path_at_pos()";

{
  my $ticker = Gtk2::Ex::TickerView->new;
  my $path = $ticker->get_path_at_pos (0, 0);
  is ($path, undef, "get_path_at_pos when no model");

  my $store = Gtk2::ListStore->new ('Glib::String');
  $ticker->set (model => $store);
  $path = $ticker->get_path_at_pos (0, 0);
  is ($path, undef, "get_path_at_pos when empty model, and unrealized");

  $ticker->set (model => undef);
  $store->set ($store->append, 0 => 'foo');
  $ticker->set (model => $store);
  $path = $ticker->get_path_at_pos (0, 0);
  isa_ok ($path, 'Gtk2::TreePath');
  if ($path) { $path = $path->to_string; }
  is ($path, '0', "get_path_at_pos when non-empty and unrealized");

  $ticker->set (model => undef);
  $store->remove ($store->iter_nth_child(undef,0));
  $ticker->set (model => $store);
  my $toplevel = Gtk2::Window->new ('toplevel');
  $toplevel->add ($ticker);
  $toplevel->show_all;
  $path = $ticker->get_path_at_pos (0, 0);
  if ($path) { $path = $path->to_string; }
  is ($path, undef, "get_path_at_pos when empty and realized");

  $toplevel->destroy;
}


#------------------------------------------------------------------------------
diag "timer run and stop";

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->append, 0 => 'foo');
  my $ticker = Gtk2::Ex::TickerView->new (model => $store,
                                          width_request => 100,
                                          height_request => 100);
  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (text => 'hello'); # dummy
  $ticker->pack_start ($renderer, 0);

  my $layout = Gtk2::Layout->new;
  $layout->set_size_request (100, 100);
  $layout->put ($ticker, 0, 0);

  my $toplevel = Gtk2::Window->new ('toplevel');
  $toplevel->add ($layout);
  $toplevel->show_all;
  wait_for_event ($ticker, 'map_event');

  ok ($ticker->{'timer'}, 'toplevel shown - timer runs');

  # container add/remove
  {
    $layout->remove ($ticker);
    ok (! $ticker->{'timer'}, 'remove from container - timer stops');

    $layout->put ($ticker, 0, 0);
    ok ($ticker->{'timer'}, 'add back to container - timer runs');
  }

  # unrealize / re-map
  {
    $ticker->unrealize;
    ok (! $ticker->{'timer'}, 'ticker unrealize - timer stops');

    $ticker->map;
    ok ($ticker->{'timer'}, 'ticker map again - timer runs');
  }

  # visibility obscure / fully visible / partly visible
  {
    my $eventbox = Gtk2::EventBox->new;
    $eventbox->set_size_request (200, 200);
    $eventbox->show;
    $layout->put ($eventbox, 0, 0);
    main_sync ($toplevel);
    ok (! $ticker->{'timer'}, 'ticker fully-obscured - timer stops');

    $layout->remove ($eventbox);
    wait_for_event ($ticker, 'visibility_notify_event');
    ok ($ticker->{'timer'}, 'ticker visible again - timer runs');

    $layout->put ($eventbox, 0, 0);
    main_sync ($toplevel);
    ok (! $ticker->{'timer'}, 'ticker fully-obscured again - timer stops');

    $layout->move ($eventbox, 10, 10);
    wait_for_event ($ticker, 'visibility_notify_event');
    ok ($ticker->{'timer'}, 'ticker partly visible - timer runs');
  }

  $toplevel->destroy;
}

#------------------------------------------------------------------------------
diag "fixed-height-mode";

{
  # Resizing stuff in a container probably, maybe, only runs when the
  # container is realized.  Is there a flag directly in the child widget
  # though?
  #
  my $ticker = Gtk2::Ex::TickerView->new;
  my $toplevel = Gtk2::Window->new ('toplevel');
  $toplevel->add ($ticker);
  $toplevel->set (resize_mode => 'immediate');
  $toplevel->show_all;
  wait_for_event ($ticker, 'map_event');

  my $resize_ran;
  $toplevel->signal_connect (check_resize => sub { $resize_ran = 1; });

  $resize_ran = 0;
  $ticker->set(fixed_height_mode => 1);
  is ($resize_ran, 0,
      'fixed-height-mode turned on -- no resize');

  $resize_ran = 0;
  $ticker->set(fixed_height_mode => 0);
  is ($resize_ran, 1,
      'fixed-height-mode turned off -- resize runs');

  $resize_ran = 0;
  $ticker->set(fixed_height_mode => 1);
  is ($resize_ran, 0,
      'fixed-height-mode turned off again -- no resize');

  $toplevel->destroy;
}

exit 0;
