#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Splash.
#
# Gtk2-Ex-Splash is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Splash is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Splash.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Glib 1.220;
use Gtk2 '-init';

use Gtk2::Ex::Splash;

use FindBin;
my $progname = $FindBin::Script;

# uncomment this to run the ### lines
use Smart::Comments;

my $rootwin = Gtk2::Gdk->get_default_root_window;
my $pixmap = Gtk2::Gdk::Pixmap->new ($rootwin, 1000, 200, -1);
$pixmap->draw_drawable (Gtk2::Gdk::GC->new($rootwin),
                        $rootwin,
                        0,0, 0,0, 500,500);
my $splash = Gtk2::Ex::Splash->new
  (
   # pixmap => $pixmap,
   filename => '/usr/share/emacs/23.2/etc/images/gnus/gnus.png',
  );


$splash->signal_connect (destroy => sub {
                           print "$progname: splash destroy\n";
                           Gtk2->main_quit;
                         });
$splash->signal_connect (button_press_event => sub {
                           print "$progname: button-press-event\n";
                         });
$splash->show;
### run-splash.pl present() done
### events: $splash->window->get_events.""

# $splash->window->set_back_pixmap ($pixmap);
# $splash->window->clear;
# Gtk2->main;
sleep 1;
$splash->unrealize;
sleep 5;
exit 0;

{
  my $pixmap2 = Gtk2::Gdk::Pixmap->new ($rootwin, 1000, 200, -1);
  my $splash2 = Gtk2::Ex::Splash->new
    (
     pixmap => $pixmap2,
    );
  $splash2->present;
  sleep 1;
  ### run-splash.pl splash2 destroy
  $splash2->destroy;
}

# my $window2 = Gtk2::Gdk::Window->new ($splash->window,
#                                       { title => 'window2',
#                                         window_type => 'child',
#                                         width  => 230,
#                                         height => 230,
#                                         x => 20,
#                                         y => 10,
#                                       });
# my $window2 = Gtk2::Gdk::Window->new ($rootwin,
#                                       { title => 'window2',
#                                         window_type => 'temp',
#                                         width  => 100,
#                                         height => 100,
#                                         x => 750,
#                                         y => 450,
#                                         override_redirect => 1,
#                                       });
# $window2->set_background (Gtk2::Gdk::Color->new(0,0,0,0xFF00FF));
# $window2->show;
# $window2->clear;
# $window2->get_display->flush;
# sleep 1;
# ### run-splash.pl window2 hide
# $window2->hide;
# $window2->get_display->flush;

# if (0) {
#   Glib::Timeout->add (1 * 1000,
#                       sub {
#                         Gtk2->main_quit;
#                         return Glib::SOURCE_REMOVE();
#                       });
#   Gtk2->main;
# } else {
#   sleep 1;
# }
# ### window2 hide
# $splash->get_display->flush;

if (0) {
  Glib::Timeout->add (50 * 1000,
                      sub {
                        Gtk2->main_quit;
                        return Glib::SOURCE_REMOVE();
                      });
  Gtk2->main;
} else {
  sleep 1;
}

$splash->hide;

my $win = Gtk2::Window->new ('toplevel');
$win->show;
$win->destroy;

exit 0;

my $window = $splash->window;
my $xid = $window->XID;
system "xwininfo -events -id $xid";
# $window->set_events ([]);
# system "xwininfo -events -id $xid";

Glib::Timeout->add (5 * 1000,
                    sub {
                      $splash->destroy;
                      return Glib::SOURCE_REMOVE();
                    });
Gtk2->main;


__END__

  # Thought for a while that the set_back_pixmap or the clear had to wait
  # until getting the map_event back from the server, but just a ->clear
  # here seems to be enough.
  #
  #
  # # $self->window is override_redirect and therefore won't go to the window
  # # manager.  A map_event should be received from the server simply after a
  # # sync.
  # #
  # if ($self->can('get_display')) { # new in Gtk 2.2
  #   ### get_display sync
  #   $self->get_display->sync;
  # } else {
  #   ### flush() is XSync in Gtk 2.0.x
  #   Gtk2::Gdk->flush;
  # }
  #
  # # wait for map_event or no more events, whichever comes first
  # # $limit is meant to
  # $self->{'seen_map_event'} = 0;
  # my $limit = 1000;
  # while (Gtk2->events_pending && ! $self->{'seen_map_event'} && --$limit > 0) {
  #   # if (my $event = Gtk2::Gdk::Event->peek) {
  #   #   ### event: $event
  #   #   ### type: $event && $event->type
  #   # }
  #   Gtk2->main_iteration_do(0); # non-blocking
  # }

# sub _do_map_event {
#   my $self = shift;
#   ### Splash _do_map_event()
# #  $self->{'seen_map_event'} = 1;
#   $self->signal_chain_from_overridden (@_);
# }



sub _do_unmap {
  my $self = shift;
  ### Splash _do_unmap()
  $self->signal_chain_from_overridden ();

  # foreach my $instance (values %instances) {
  #   if ($instance && $instance->mapped && (my $window = $instance->window)) {
  #     if ($self->can('get_screen') # new in Gtk 2.2
  #         && $self->get_screen != $instance->get_screen) {
  #       next;
  #     }
  #     ### clear other instance: "$instance"
  #     $window->clear;
  #     _flush ($instance);
  #   }
  # }
  # 
  # _flush ($self);
  ### _do_unmap() finished
}


  # Creating a window explicitly doesn't seem to work very well.  Think
  # setting override_redirect after creating is good enough.
  #
  # Think window_type=>'temp' means override_redirect=>1 already.
  # my $rootwin = ($self->{'root_window'}
  #                || ($self->{'screen'} && $self->{'screen'}->get_root_window)
  #                || Gtk2::Gdk->get_default_root_window);
  # my $window = Gtk2::Gdk::Window->new ($rootwin,
  #                                      { window_type => 'temp',
  #                                        width  => 100,
  #                                        height => 100,
  #                                        override_redirect => 1,
  #                                      });
  # $self->window ($window);
  # my $style = $self->style;
  # $self->set_style ($style->attach($window)); # create gc's etc

