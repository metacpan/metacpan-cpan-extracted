# Copyright 2008, 2009, 2012 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.


# This is a kind of output-only example, where a CheckButton controls the
# text displayed in a label, with no intention to have a change to the label
# propagate back to the button (unlike most ConnectProperties uses).
#
# This is a nice way to keep a label up-to-date, though it's also something
# you can do very easily with a signal handler instead of a
# ConnectProperties.
#

use strict;
use warnings;
use Gtk2 '-init';
use Glib::Ex::ConnectProperties;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (0,0);
$toplevel->add ($vbox);

my $button = Gtk2::CheckButton->new_with_label ('Click Me');
$vbox->pack_start ($button, 1, 1, 0);

my $label = Gtk2::Label->new;
$vbox->pack_start ($label, 1, 1, 0);

Glib::Ex::ConnectProperties->new
  ([$button, 'active'],
   [$label, 'label',
    func_in => sub { $_[0] ? "pressed" : "not pressed"},
    write_only => 1 ]);

$toplevel->show_all;
Gtk2->main;
exit 0;
