#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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


use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::ActionTooltips;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to Gtk2->init_check() unsuccessful';

plan tests => 14;

{
  my $want_version = 48;
  is ($Gtk2::Ex::ActionTooltips::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::ActionTooltips->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { Gtk2::Ex::ActionTooltips->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::ActionTooltips->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

require Gtk2;
MyTestHelpers::glib_gtk_versions();


#----------------------------------------------------------------------------
# group_tooltips_to_menuitems()

{
  my $actiongroup = Gtk2::ActionGroup->new ('test1');
  Gtk2::Ex::ActionTooltips::group_tooltips_to_menuitems ($actiongroup);

  $actiongroup->add_actions
    ([# name,        stock-id,  label
      [ 'FileMenu',   undef,    '_File'  ],

      # name,       stock id,     label,  accelerator,  tooltip

      [ 'Open',     'gtk-open',   undef,  'O',   'The tooltip for Open',
        sub { return 'Open something'; }
      ],
     ]);
  my $ui = Gtk2::UIManager->new;
  $ui->insert_action_group ($actiongroup, 0);

  $ui->add_ui_from_string (<<'HERE');
<ui>
  <menubar name='MenuBar'>
    <menu action='FileMenu'>
      <menuitem action='Open'/>
    </menu>
  </menubar>
</ui>
HERE

  my $menuitem = $ui->get_widget('/MenuBar/FileMenu/Open');
  isa_ok ($menuitem, 'Gtk2::MenuItem');
 SKIP: {
    $menuitem->can('get_tooltip_text')
      or skip 'get_tooltip_text() not available', 1;
    is ($menuitem->get('tooltip-text'),
        'The tooltip for Open',
        'MenuItem tooltip value');
  }
}


#----------------------------------------------------------------------------
# action_tooltips_to_menuitems_dynamic()

{
  my $actiongroup = Gtk2::ActionGroup->new ('test1');
  $actiongroup->add_actions
    ([# name,        stock-id,  label
      [ 'FileMenu',   undef,    '_File'  ],
     ]);

  my $action1 = Gtk2::Action->new (name     => 'Quit',
                                   stock_id => 'gtk-quit',
                                   tooltip  => 'The initial tooltip for Quit');
  my $action2 = Gtk2::Action->new (name     => 'Close',
                                   label    => 'Close It',
                                   tooltip  => 'The Close first tooltip');
  $actiongroup->add_action ($action1);
  $actiongroup->add_action ($action2);

  Gtk2::Ex::ActionTooltips::action_tooltips_to_menuitems_dynamic
      ($action1, $action2);

  my $ui = Gtk2::UIManager->new;
  $ui->insert_action_group ($actiongroup, 0);

  $ui->add_ui_from_string (<<'HERE');
<ui>
  <menubar name='MenuBar'>
    <menu action='FileMenu'>
      <menuitem action='Quit'/>
      <menuitem action='Close'/>
    </menu>
  </menubar>
</ui>
HERE

  my $quit_item = $ui->get_widget('/MenuBar/FileMenu/Quit');
  isa_ok ($quit_item, 'Gtk2::MenuItem');

  my $close_item = $ui->get_widget('/MenuBar/FileMenu/Close');
  isa_ok ($close_item, 'Gtk2::MenuItem');

 SKIP: {
    $quit_item->can('set_tooltip_text')
      or skip 'set_tooltip_text() not available', 6;

    is ($quit_item->get('tooltip-text'),
        'The initial tooltip for Quit',
        'Initial Quit tooltip value');
    is ($close_item->get('tooltip-text'),
        'The Close first tooltip',
        'Initial Close tooltip value');

    $action1->set(tooltip => 'The second tooltip for Quit');

    is ($quit_item->get('tooltip-text'),
        'The second tooltip for Quit',
        'Second Quit tooltip value');
    is ($close_item->get('tooltip-text'),
        'The Close first tooltip',
        'Initial Close tooltip value - unchanged');

    $action2->set(tooltip => 'The Close second tip');

    is ($quit_item->get('tooltip-text'),
        'The second tooltip for Quit',
        'Second Quit tooltip value - unchanged');
    is ($close_item->get('tooltip-text'),
        'The Close second tip',
        'Second Close tooltip value');
  }
}

exit 0;
