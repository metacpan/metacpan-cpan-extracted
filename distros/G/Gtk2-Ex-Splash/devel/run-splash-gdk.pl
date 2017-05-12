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

use Gtk2::Ex::SplashGdk;

use FindBin;
my $progname = $FindBin::Script;

# uncomment this to run the ### lines
use Smart::Comments;

# my $w = Glib::Object::new ('Gtk2::Gdk::Window');
# ### $w
# $w->show;

my $rootwin = Gtk2::Gdk->get_default_root_window;
my $pixmap = Gtk2::Gdk::Pixmap->new ($rootwin, 1000, 200, -1);
my $splash = Gtk2::Ex::SplashGdk->new
  (# pixmap => $pixmap,
   filename => '/usr/share/emacs/23.2/etc/images/gnus/gnus.png',
  );
### $splash
# $splash->signal_connect (destroy => sub { Gtk2->main_quit });
# $splash->signal_connect (button_press_event => sub {
#                            print "$progname: button-press-event\n";
#                          });

Gtk2::Widget->signal_add_emission_hook
  (event => sub {
     my ($invocation_hint, $parameters) = @_;
     my ($widget, $event) = @$parameters;
     print "$progname: event",$event->type,"\n";
     return 1; # stay connected
   });

$splash->show;
sleep 5;
exit 0;
my $xid = $splash->{'window'}->XID;
# $splash->get_display->flush;

system "xwininfo -events -id $xid";

Glib::Timeout->add (5 * 1000,
                    sub {
                      $splash->hide;
                      return Glib::SOURCE_REMOVE();
                    });
Gtk2->main;
