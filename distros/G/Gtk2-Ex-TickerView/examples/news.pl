#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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


# This is an example news ticker, using a Gtk2::ListStore as the underlying
# model.  The first entry in the list is updated under a timer to show the
# current time and you can see it getting redrawn automatically on each
# change to the model (including updating during a user drag).
#
# There's two renderers, a pixbuf showing a yellow house icon, then a text
# renderer for the string from the model.  The pixbuf could be made to vary
# with the model if desired, eg. a different icon for sports, weather, etc.
#

use strict;
use warnings;
use POSIX ();
use Gtk2 '-init';
use Gtk2::Ex::TickerView;

my @house_xpm = (
'32 32 2 1',
' 	c None',
'.	c yellow',
'                                ',
'                                ',
'               ..               ',
'            ........            ',
'          ....    ....          ',
'        ....        ....        ',
'     ....              ....     ',
'   ....                  ....   ',
' ... ...................... ... ',
'...  ......................  ...',
'     ..                  ..     ',
'     ..                  ..     ',
'     ..                  ..     ',
'     ..                  ..     ',
'     ..                  ..     ',
'     ..                  ..     ',
'     ..                  ..     ',
'     ..                  ..     ',
'     ..                  ..     ',
'     ..       ........   ..     ',
'     ..       ........   ..     ',
'     ..       ..    ..   ..     ',
'     ..       ..    ..   ..     ',
'     ..       ..    ..   ..     ',
'     ..       ..    ..   ..     ',
'     ..       ..    ..   ..     ',
'     ..       ..    ..   ..     ',
'     ......................     ',
'     ......................     ',
'                                ',
'                                ',
'                                ');

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });
$toplevel->set_size_request (300, -1);

my $liststore = Gtk2::ListStore->new ('Glib::String');
foreach my $str ('News time 12:34:56',
                 'Barbers Union boycotts fringe festival',
                 'Scientists say space is big - really, really, big',
                 'Colonel Kurtz denies his methods are unsound',
                 'Norville Barnes appointed president of Hudsucker',
                ) {
  $liststore->set_value ($liststore->append, 0, $str);
}

my $ticker = Gtk2::Ex::TickerView->new (model => $liststore);
$toplevel->add ($ticker);

my $renderer1 = Gtk2::CellRendererPixbuf->new;
$renderer1->set (pixbuf => Gtk2::Gdk::Pixbuf->new_from_xpm_data (@house_xpm),
                 xpad   => 4);
$ticker->pack_start ($renderer1, 0);

my $renderer2 = Gtk2::CellRendererText->new;
$ticker->pack_start ($renderer2, 0);
$ticker->set_attributes ($renderer2, markup => 0);

sub timer_callback {
  # note POSIX::strftime is locale bytes, so really ought to recode it to
  # perl wide-char unicode here, but %H%M%S is only digits
  my $str = POSIX::strftime ("News time <tt>%H:%M:%S</tt>",
                             localtime (time()));
  $liststore->set_value ($liststore->get_iter_first, 0, $str);
  return 1; # Glib::SOURCE_CONTINUE
}
timer_callback();                            # initial time display
Glib::Timeout->add (1000, \&timer_callback); # periodic updates

# setup a couple of key bindings, space to toggle the run, Q to quit
$ticker->add_events (['key-press-mask']);
$ticker->set_flags ('can-focus');
$ticker->signal_connect
  (key_press_event => sub {
     my ($ticker, $event) = @_;
     my $keyval = Gtk2::Gdk->keyval_to_upper ($event->keyval);
     if ($keyval == Gtk2::Gdk->keyval_from_name ('space')) {
       $ticker->set (run => ! $ticker->get('run'));
     } elsif ($keyval == Gtk2::Gdk->keyval_from_name ('Q')) {
       $toplevel->destroy;
     }
     return 0; # Gtk2::EVENT_PROPAGATE
   });

$toplevel->show_all;
Gtk2->main;
exit 0;
