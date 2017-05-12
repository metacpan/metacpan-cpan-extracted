#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetCursor.
#
# Gtk2-Ex-WidgetCursor is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetCursor is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetCursor.  If not, see <http://www.gnu.org/licenses/>.


# A grab bag of cursor things turned on and off and interacting or not.
# Run it and click the buttons and move the mouse around to try stuff.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::WidgetCursor;

use FindBin;
my $progname = $FindBin::Script;

{
  my $toplevel = Gtk2::Window->new ('toplevel');
  $toplevel->set_name ("my_toplevel_1");
  $toplevel->signal_connect (destroy => sub {
                               print "$progname: quit\n";
                               Gtk2->main_quit;
                             });

  my $hbox = Gtk2::HBox->new (0, 0);
  $toplevel->add ($hbox);

  my $vbox = Gtk2::VBox->new (0, 0);
  $hbox->pack_start ($vbox, 0, 0, 0);

  my $area = Gtk2::DrawingArea->new;
  $hbox->pack_start ($area, 1, 1, 0);
  {
    $area->set_size_request (100, 100);
    my $label = Gtk2::Label->new("Drag Here");
    $area->add_events (['button-press-mask', 'button-release-mask']);
    $area->signal_connect
      (expose_event => sub {
         my $layout = $area->create_pango_layout ("Drag Here");
         $area->window->draw_layout
           ($area->style->fg_gc($area->state), 0, 0, $layout);
       });
    my $drag_cursor;
    $area->signal_connect
      (button_press_event => sub {
         if ($drag_cursor) {
           print "$progname: drag_cursor still set $drag_cursor\n";
         }
         $drag_cursor = Gtk2::Ex::WidgetCursor->new (widget => $area,
                                                     cursor => 'hand1',
                                                     active => 1);
         print "$progname: drag cursor $drag_cursor\n";
       });
    $area->signal_connect
      (button_release_event => sub {
         $drag_cursor = undef;
       });
  }

  my $vbox2 = Gtk2::VBox->new;
  $hbox->pack_start ($vbox2, 1, 1, 0);

  my $textbuf = Gtk2::TextBuffer->new;
  $textbuf->set_text ("hello\nworld\n");
  my $textview = Gtk2::TextView->new;
  $textview->set_size_request (100, 100);
  $vbox2->pack_start ($textview, 1, 1, 0);

  {
    my $entry = Gtk2::Entry->new;
    $vbox2->pack_start ($entry, 1, 1, 0);
  }

  my $base = Gtk2::Ex::WidgetCursor->new (widget => $toplevel,
                                         include_children => 1);
  print "$progname: base $base\n";
  {
    my $button = Gtk2::Button->new_with_label ("Boat");
    $button->signal_connect (clicked => sub {
                               print "$progname: boat\n";
                               $base->cursor('boat');
                               $base->active (1);
                             });
    $vbox->pack_start ($button, 0, 0, 0);
  }
  {
    my $button = Gtk2::Button->new_with_label ("Umbrella");
    $button->signal_connect (clicked => sub {
                               print "$progname: umbrella\n";
                               $base->cursor('umbrella');
                               $base->active (1);
                             });
    $vbox->pack_start ($button, 0, 0, 0);
  }
  {
    my $button = Gtk2::Button->new_with_label ("Busy");
    $button->signal_connect (clicked => sub {
                               print "$progname: busy\n";
                               Gtk2::Ex::WidgetCursor->busy;
                               sleep (3);
                             });
    $vbox->pack_start ($button, 0, 0, 0);
  }
  {
    my $wc = Gtk2::Ex::WidgetCursor->new (widget => $area,
                                          cursor => 'heart');
    print "$progname: heart $wc\n";
    my $id;
    sub heart_on {
      $wc->active (1);
      $id = Glib::Timeout->add (1000, \&heart_off);
      return 0; # remove this timer
    }
    sub heart_off {
      $wc->active (0);
      $id = Glib::Timeout->add (1000, \&heart_on);
      return 0; # remove this timer
    }

    my $button = Gtk2::CheckButton->new_with_label ("Heart");
    $button->signal_connect (clicked => sub {
                               if ($button->get_active) {
                                 if (! $id) {
                                   heart_on ();
                                 }
                               } else {
                                 if ($id) {
                                   $wc->active (0);
                                   Glib::Source->remove ($id);
                                   $id = undef;
                                 }
                               }
                             });
    $vbox->pack_start ($button, 0, 0, 0);
  }

  my $link_button = Gtk2::LinkButton->new ('http://localhost/index.html',
                                           'Link Button');
  # $link_button->set_size_request (-1, 50);
  print "$progname: link button flags", $link_button->flags, "\n";
  $vbox->pack_start ($link_button, 0, 0, 0);

  {
    my $eventbox = Gtk2::EventBox->new;
    $vbox->pack_start ($eventbox, 0, 0, 0);
    my $button = Gtk2::LinkButton->new ('http://localhost/index.html',
                                        'Link in EventBox');
    $eventbox->add ($button);
  }

  {
    my $button = Gtk2::CheckButton->new_with_label ("Top set_cursor");
    $button->signal_connect
      (clicked => sub {
         my $win = $toplevel->window;
         print "$progname: toplevel window $win\n";
         print "  link button window    ",$link_button->window,"\n";
         $win->set_cursor ($button->get_active
                           ? Gtk2::Gdk::Cursor->new('gobbler') : undef);
       });
    $vbox->pack_start ($button, 0, 0, 0);
  }

  {
    my $button = Gtk2::Button->new_with_label ("Busy Shortly");
    $button->signal_connect
      (clicked => sub {
         Glib::Timeout->add (1000, sub {
                               print "$progname: busy\n";
                               Gtk2::Ex::WidgetCursor->busy;
                               sleep (3);
                               return 0; # stop timer
                             });
       });
    $vbox->pack_start ($button, 0, 0, 0);
  }
  {
    my $button = Gtk2::Button->new_with_label ("Pointer Grab");
    $button->signal_connect
      (clicked => sub {
         my $event = Gtk2->get_current_event;
         my $window = $area->window;
         my $event_mask = [];
         my $confine_to = undef;
         my $cursor = undef;
         my $time = $event->time;

         print "$window, 1, $event_mask, ",
           defined $confine_to ? $confine_to : 'undef',",",
             " ", defined $cursor ? $cursor : 'undef',",",
               " $time\n";
         my $status = Gtk2::Gdk->pointer_grab
           ($window, 1, $event_mask, $confine_to, $cursor, $time);
         print "$progname: grab $status\n";

       });
    $vbox->pack_start ($button, 0, 0, 0);
  }
  {
    my $screen = $toplevel->get_screen;
    my $confine_win = Gtk2::Gdk::Window->new
      ($screen->get_root_window,
       { window_type => 'temp',
         wclass      => 'GDK_INPUT_ONLY',
         x           => $screen->get_width / 2,
         y           => $screen->get_height / 2,
         width       => $screen->get_width / 2,
         height      => $screen->get_height / 2,
         override_redirect => 1 });

    my $button = Gtk2::Button->new_with_label ("Confined Grab");
    $button->signal_connect
      (clicked => sub {
         my $event = Gtk2->get_current_event;
         my $window = $area->window;
         my $event_mask = [];
         my $cursor = undef;
         my $time = $event->time;
         $confine_win->show;

         my $status = Gtk2::Gdk->pointer_grab
           ($window, 1, $event_mask, $confine_win, $cursor, $time);
         print "$progname: grab $status\n";

       });
    $vbox->pack_start ($button, 0, 0, 0);
  }
  Gtk2->key_snooper_install
    (sub {
       print "$progname: pointer_ungrab\n";
       Gtk2::Gdk->pointer_ungrab (0);
     });

  {
    my $combobox = Gtk2::ComboBox->new_text;
    $vbox->pack_start ($combobox, 1,1,0);
    foreach ('one', 'two', 'three', 'four') {
      $combobox->append_text ($_);
    }
    $combobox->set_active (0);
  }

  $toplevel->show_all;
}

{
  my $display_name = Gtk2::Gdk::Display->get_default->get_name;
  my $display = Gtk2::Gdk::Display->open ($display_name);
  my $screen = $display->get_default_screen;
  my $toplevel = Gtk2::Window->new ('toplevel');
  $toplevel->set_name ("my_toplevel_2");
  $toplevel->set_screen ($screen);
  $toplevel->set_size_request (100, 100);
  $toplevel->signal_connect (destroy => sub {
                               print "$progname: second toplevel quit\n";
                               Gtk2->main_quit;
                             });
  $toplevel->{'mycursor'} = Gtk2::Ex::WidgetCursor->new (widget => $toplevel,
                                                         cursor => 'fleur',
                                                         active => 1);

  print "$progname: second toplevel $toplevel\n";
  $toplevel->show_all;
}

print "$progname: toplevel widgets are\n";
foreach my $widget (Gtk2::Window->list_toplevels) {
  print "  $widget  ", $widget->get_name, "\n";

  if ($widget->get_name =~ /Gtk/) {
    foreach my $widget (Gtk2::Ex::WidgetCursor::_container_recursively ($widget)) {
      print "    $widget  ", $widget->get_name, "\n";
    }
  }
}

Gtk2->main;
exit 0;


__END__
