#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl action-tooltips.pl
#
# This is an example of putting tooltips from Gtk2::Action objects onto
# Gtk2::MenuItem widgets connected to those actions.
#
# * group_tooltips_to_menuitems() sets the tooltip just once, when called or
#   when a new MenuItem is connected.  It's suitable for things like the Quit
#   action where the message doesn't change, which is the case for most
#   actions.
#
#   You can put the group setup before or after adding its actions.  In the
#   code below it's immediately on creating the group, so before any
#   actions.
#
# * action_tooltips_to_menuitems_dynamic() on $my_action makes future
#   changes to its tooltip propagate to its menu items.  This is independent
#   of the group tooltips setup, you can the two things separately or
#   together.
#
#   The tooltip in $my_action is updated with the current time.  Notice how
#   it even changes while popped up.  Showing the time is pretty silly,
#   realistically you'd probably only update tooltips to make a message
#   specific to a given document or viewing mode.
#
# Apart from that the UIManager parts here are fairly typical, though also
# fairly tedious.  The action and action group stuff can also be used
# separately, with directly created menubars etc, though supposedly the
# UIManager mechanism lets users work their own extra things into the GUI.
#

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::ActionTooltips;
use POSIX 'strftime';

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $actiongroup = Gtk2::ActionGroup->new ('my-action-group');
Gtk2::Ex::ActionTooltips::group_tooltips_to_menuitems ($actiongroup);

$actiongroup->add_actions
  ([
    { name  => 'FileMenu',
      label => '_File',
    },

    { name  => 'MyAction',
      label => '_MyAction',
      # tooltip is set in the code below
      callback => sub {
        print "MyAction runs\n";
      },
    },
    { name => 'Quit',
      label => '_Quit',
      tooltip => 'Quit means close the window and exit the program',
      callback => sub {
        $toplevel->destroy;
      },
    },
   ]);

my $my_action = $actiongroup->get_action('MyAction');
Gtk2::Ex::ActionTooltips::action_tooltips_to_menuitems_dynamic ($my_action);

Glib::Timeout->add
  (1000, sub {
     my $tip = strftime ('As of %H:%M:%S, this is the tooltip for my action',
                         localtime (time()));
     $my_action->set (tooltip => $tip);
     return 1; # Glib::SOURCE_CONTINUE
   });

my $ui = Gtk2::UIManager->new;
$ui->insert_action_group ($actiongroup, 0);

$ui->add_ui_from_string (<<'HERE');
<ui>
  <menubar name='MenuBar'>
    <menu action='FileMenu'>
      <menuitem action='MyAction'/>
      <menuitem action='Quit'/>
    </menu>
  </menubar>
  <toolbar  name='ToolBar'>
    <toolitem action='MyAction'/>
    <toolitem action='Quit'/>
  </toolbar>
</ui>
HERE

$vbox->pack_start ($ui->get_widget('/MenuBar'), 0,0,0);
$vbox->pack_start ($ui->get_widget('/ToolBar'), 0,0,0);

my $label = Gtk2::Label->new (<<'HERE');
Move the mouse over the tool items or
the menu items (after you popup the menu)
to see the tooltips.
HERE
$vbox->pack_start ($label, 1,1,0);

$toplevel->show_all;
Gtk2->main;
exit 0;
