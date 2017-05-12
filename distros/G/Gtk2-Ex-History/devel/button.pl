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

my $history2 = Gtk2::Ex::History->new;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

#my $histbutton = Gtk2::Ex::History::Button->new;
my $histbutton = Gtk2::Ex::History::MenuToolButton->new;
print "$progname: ", $histbutton->get('way'), "\n";
$vbox->pack_start ($histbutton, 1,1,0);

{
  my $button = Gtk2::Button->new ('Set history');
  $button->signal_connect
    (clicked => sub {
       $histbutton->set (history => $history);
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new ('Set history 2');
  $button->signal_connect
    (clicked => sub {
       $histbutton->set (history => $history2);
     });
  $vbox->pack_start ($button, 0,0,0);
}

{
  my $button = Gtk2::Button->new ('Set back');
  $button->signal_connect
    (clicked => sub {
       $histbutton->set (way => 'back');
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new ('Set forward');
  $button->signal_connect
    (clicked => sub {
       $histbutton->set (way => 'forward');
     });
  $vbox->pack_start ($button, 0,0,0);
}

{
  my $button = Gtk2::Button->new ('Go back');
  $button->signal_connect
    (clicked => sub {
       $history->back;
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new ('Go forward');
  $button->signal_connect
    (clicked => sub {
       $history->forward;
     });
  $vbox->pack_start ($button, 0,0,0);
}

$toplevel->show_all;
Gtk2->main;
exit 0;
