#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-DateSpinner.
#
# Gtk2-Ex-DateSpinner is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-DateSpinner is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-DateSpinner.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2 '-init';

use FindBin;
my $progname = $FindBin::Script;

my $model = Gtk2::ListStore->new ('Glib::String');
$model->insert_with_values (0, 0 => 'food');
$model->insert_with_values (1, 0 => 'foobar');
$model->insert_with_values (2, 0 => 'xyzzy');

my $completion = Gtk2::EntryCompletion->new;
$completion->set_model ($model);
$completion->set_text_column (0);
$completion->set_popup_completion (1);

my $setname = 'Gtk2::Ex::Entry::WithCancel';
$setname =~ tr/:/_/;
$setname .= '_keys';

my $entry = Gtk2::Entry->new;
$entry->set_completion ($completion);

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

print "$progname: entry name ",$entry->get_name,"\n";
$vbox->pack_start ($entry, 0,0,0);
$entry->signal_connect (activate => sub {
                          print "$progname: activate signal\n";
                        });
$entry->signal_connect
  (key_press_event => sub {
     my ($entry, $event) = @_;
     print "$progname: keyval=",$event->keyval,
       " keycode=", $event->hardware_keycode,
       " group=", $event->group, "\n";
     return 0; # Gtk2::EVENT_PROPAGATE
   });


$toplevel->show_all;
Gtk2->main;
exit 0;
