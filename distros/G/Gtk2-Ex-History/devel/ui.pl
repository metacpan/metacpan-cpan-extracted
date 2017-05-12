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
use Gtk2::Ex::History::Action;

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
$history->signal_connect
  ('notify::current' => sub {
     print "$progname: notify::current ",$history->get('current'),"\n";
   });

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $actiongroup = Gtk2::ActionGroup->new ("main");
$actiongroup->add_actions ([
                            { name => 'FileMenu',  label => '_File'  },
                            { name     => 'Quit',
                              stock_id => 'gtk-quit',
                              callback => sub { $toplevel->destroy },
                            },
                            { name     => 'Hello',
                              stock_id => 'gtk-quit',
                              callback => sub { print "hello\n" },
                            },
                           ]);
$actiongroup->add_action
  (Gtk2::Ex::History::Action->new (name    => 'Back',
                                   way     => 'back',
                                   history => $history));
$actiongroup->add_action
  (Gtk2::Ex::History::Action->new (name    => 'Forward',
                                   way     => 'forward',
                                   history => $history));

# makes a Gtk2::MenuToolButton
my $recentaction = Gtk2::RecentAction->new (name => 'Recent',
                                            label => 'Recently',
                                            stock_id => 'gtk-open');
$actiongroup->add_action ($recentaction);

my $ui = Gtk2::UIManager->new;
$ui->insert_action_group ($actiongroup, 0);
$toplevel->add_accel_group ($ui->get_accel_group);
$ui->add_ui_from_string ("
<ui>
  <toolbar name='ToolBar'>
    <toolitem action='Back'/>
    <toolitem action='Recent'>
      <menu action='FileMenu'>
        <menuitem action='Quit'/>
      </menu>
    </toolitem>
  </toolbar>
</ui>");

my $toolbar = $ui->get_widget ('/ToolBar');
$toplevel->add ($toolbar);

my $req = $toolbar->size_request;
$toplevel->set_default_size (200, 100);

$toplevel->show_all;
Gtk2->main;
exit 0;
