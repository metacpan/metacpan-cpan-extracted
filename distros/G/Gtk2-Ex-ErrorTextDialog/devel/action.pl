#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-ErrorTextDialog.
#
# Gtk2-Ex-ErrorTextDialog is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ErrorTextDialog is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ErrorTextDialog.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Data::Dumper;
use Gtk2 '-init';

require 'devel/Action.pm';

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->set_default_size (200, -1);
$toplevel->signal_connect (destroy => sub {
                             print "$progname: quit\n";
                             Gtk2->main_quit;
                           });

my $vbox = Gtk2::VBox->new (0, 0);
$toplevel->add ($vbox);

my $actiongroup = Gtk2::ActionGroup->new ("main");

my $action = Gtk2::Ex::ErrorTextDialog::Action->new;
# (name => 'MyErrorTextDialog');
$actiongroup->add_action_with_accel ($action, '<Ctrl><Shift>E');

my $ui = Gtk2::UIManager->new;
$toplevel->add_accel_group ($ui->get_accel_group);
$ui->insert_action_group ($actiongroup, 0);

$actiongroup->add_actions
  ([
    { name => 'FileMenu',  label => '_File'  },
   ],
   'my-userdata');

$ui->add_ui_from_string (<<'HERE');
<ui>
  <menubar name='MenuBar'>
    <menu action='FileMenu'>
      <menuitem action='ErrorTextDialog'/>
    </menu>
  </menubar>
  <toolbar  name='ToolBar'>
    <toolitem action='ErrorTextDialog'/>
  </toolbar>
</ui>
HERE

my $menubar = $ui->get_widget ('/MenuBar');
$vbox->pack_start ($menubar, 0,0,0);

my $toolbar = $ui->get_widget ('/ToolBar');
$vbox->pack_start ($toolbar, 0,0,0);

$toplevel->show_all;
Gtk2->main;
exit 0;
