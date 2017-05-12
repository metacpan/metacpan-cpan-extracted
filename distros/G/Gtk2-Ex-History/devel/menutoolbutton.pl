#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-History.
#
# Gtk2-Ex-History is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-History is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-History.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::History;
use Gtk2::Ex::History::MenuToolButton;

# uncomment this to run the ### lines
use Smart::Comments;

use FindBin;
my $progname = $FindBin::Script;

my $history = Gtk2::Ex::History->new;
$history->goto ('AAA');
$history->goto ('BBB');
$history->goto ('CCC');
$history->goto ('DDD');
$history->goto ('EEE');
$history->goto ('FFF');
$history->goto ('GGG');
$history->back(3);

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (100, 50);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $toolbar = Gtk2::Toolbar->new;
# my $toolbar = Gtk2::VBox->new;
$vbox->pack_start ($toolbar, 1,1,0);

# my $toolbutton = Gtk2::MenuToolButton->new_from_stock ('gtk-go-back');
# require Gtk2::Ex::History::Menu;
# my $menu = Gtk2::Ex::History::Menu->new (history => $history,
#                                          way => 'back');
# $toolbutton->set_menu ($menu);

my $toolbutton = Gtk2::Ex::History::MenuToolButton->new (history => $history,
                                                         way => 'forward');

{
  my $item = Gtk2::ToolButton->new (undef, 'ChangeWay');
  $item->signal_connect (clicked => sub {
                           my $way = $toolbutton->get('way');
                           if ($way eq 'back') { $way = 'forward'; }
                           else                { $way = 'back'; }
                           $toolbutton->set('way', $way);
                         });
  $toolbar->add ($item);
}

$toolbar->add ($toolbutton);

$toplevel->show_all;
Gtk2->main;
exit 0;
