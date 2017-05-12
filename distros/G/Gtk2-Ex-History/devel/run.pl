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
use Gtk2::Ex::History::Button;
use Gtk2::Ex::History::Dialog;

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

# {
#   my $back = $history->model('back');
#   ### $back
#   use List::Util;
#   my $aref = [123];
#   my @foo = ($aref);
#   Scalar::Util::weaken ($foo[0]);
#   List::Util::first {
#     ### $_
#     (defined $_ && $_==123)
#   } @{$back->{'others'}};
#   exit 0;
# }

my $d2 = Gtk2::Gdk::Display->open (':3');

my $toplevel = Gtk2::Window->new('toplevel');
if ($d2) {
  $toplevel->set_screen ($d2->get_default_screen);
}
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

{
  my $menubar = Gtk2::MenuBar->new;
  $vbox->pack_start ($menubar, 0,0,0);

  my $foo_item = Gtk2::MenuItem->new_with_label ('Foo');
  $menubar->add ($foo_item);

  my $menu = Gtk2::Menu->new;
  $foo_item->set_submenu ($menu);

  my $back_item = Gtk2::MenuItem->new_with_label ('Back to');
  $menu->add ($back_item);

  require Gtk2::Ex::History::Menu;
  my $histmenu = Gtk2::Ex::History::Menu->new (history => $history,
                                               way => 'back');
  $back_item->set_submenu ($histmenu);
}

my $hbox = Gtk2::HBox->new;
$vbox->pack_start ($hbox, 1,1,0);
{
  my $button = Gtk2::Ex::History::Button->new (history => $history,
                                               # way => 'back',
                                              );
  print "$progname: ", $button->get('way'), "\n";
  $hbox->pack_start ($button, 1,1,0);
}
{
  my $button = Gtk2::Ex::History::Button->new (history => $history,
                                               way => 'forward',
                                              );
  $hbox->pack_start ($button, 1,1,0);
}

{
  my $button = Gtk2::Button->new ('Menu');
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect
    (clicked => sub {
       require Gtk2::Ex::History::Menu;
       my $menu = Gtk2::Ex::History::Menu->new_popup (history => $history);
     });
}
{
  my $button = Gtk2::Button->new ('Dialog');
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect
    (clicked => sub {
       require Gtk2::Ex::History::Dialog;
       my $menu = Gtk2::Ex::History::Dialog->popup ($history);
     });
}

# Gtk2::Ex::History::Dialog->popup ($history);

# my $recent = Gtk2::RecentChooserDialog->new ('Recently', undef);
# $recent->show;

$toplevel->show_all;
Gtk2->main;
exit 0;
