# Copyright 2008, 2009 Kevin Ryde

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


use strict;
use warnings;
use Gtk2 '-init';

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (0,0);
$toplevel->add ($vbox);

my $label = Gtk2::Label->new ('Hello');
$vbox->add ($label);

my $check = Gtk2::CheckButton->new_with_label ('Sensitive');
$vbox->add ($check);

my $button = Gtk2::Button->new_with_label ('Press Me');
$vbox->add ($button);


$check->signal_connect (toggled => sub {
                           print "check toggled, set label sensitive\n";
                           $label->set_sensitive ($check->get_active);
                         });

$label->signal_connect ('notify::sensitive' => sub {
                          print "label notify::sensitive, set check\n";
                          $check->set_active ($label->get('sensitive'));
                        });

$button->signal_connect (clicked => sub {
                           print "button pressed, set label sensitive\n";
                           $label->set_sensitive (1);
                         });


$toplevel->show_all;
Gtk2->main;
exit 0;
