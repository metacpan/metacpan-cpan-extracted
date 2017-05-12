#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-ComboBoxBits.
#
# Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ComboBoxBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';
MyTestHelpers::glib_gtk_versions();

plan tests => 32;

require Gtk2::Ex::ToolItem::ComboEnum;
diag "Buildable: ",Gtk2::Ex::ToolItem::ComboEnum->isa('Gtk2::Buildable')||0;

Glib::Type->register_enum ('My::Test1', 'foo', 'bar-ski', 'quux');

#------------------------------------------------------------------------------
# VERSION

my $want_version = 32;
{
  is ($Gtk2::Ex::ToolItem::ComboEnum::VERSION,
      $want_version,
      'VERSION variable');
  is (Gtk2::Ex::ToolItem::ComboEnum->VERSION,
      $want_version,
      'VERSION class method');

  ok (eval { Gtk2::Ex::ToolItem::ComboEnum->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::ToolItem::ComboEnum->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $toolitem = Gtk2::Ex::ToolItem::ComboEnum->new;
  isa_ok ($toolitem, 'Gtk2::Ex::ToolItem::ComboEnum');  
  is ($toolitem->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $toolitem->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $toolitem->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}


#-----------------------------------------------------------------------------
# Scalar::Util::weaken

{
  my $toolitem = Gtk2::Ex::ToolItem::ComboEnum->new;
  require Scalar::Util;
  Scalar::Util::weaken ($toolitem);
  is ($toolitem, undef, 'garbage collect when weakened');
}

{
  my $toolitem = Gtk2::Ex::ToolItem::ComboEnum->new;
  my $menuitem = $toolitem->retrieve_proxy_menu_item;

  require Scalar::Util;
  Scalar::Util::weaken ($toolitem);
  Scalar::Util::weaken ($menuitem);
  is ($toolitem, undef, 'toolitem - garbage collect when weakened');
  is ($menuitem, undef, 'menuitem - garbage collect when weakened');
}

{
  my $toolitem = Gtk2::Ex::ToolItem::ComboEnum->new;
  my $menuitem1 = $toolitem->retrieve_proxy_menu_item;
  my $menuitem2 = $toolitem->retrieve_proxy_menu_item;

  require Scalar::Util;
  Scalar::Util::weaken ($toolitem);
  Scalar::Util::weaken ($menuitem1);
  Scalar::Util::weaken ($menuitem2);
  is ($toolitem, undef, 'toolitem - garbage collect when weakened');
  is ($menuitem1, undef, 'menuitem1 - garbage collect when weakened');
  is ($menuitem2, undef, 'menuitem2 - garbage collect when weakened');
}

{
  my $toplevel = Gtk2::Window->new;
  my $toolbar = Gtk2::Toolbar->new;
  $toplevel->add($toolbar);
  my $toolitem = Gtk2::Ex::ToolItem::ComboEnum->new (enum_type => 'My::Test1');
;
  $toolbar->add ($toolitem);
  $toplevel->show_all;
  my $menuitem = $toolitem->retrieve_proxy_menu_item;
  MyTestHelpers::main_iterations();
  $toplevel->destroy;

  require Scalar::Util;
  Scalar::Util::weaken ($toolitem);
  Scalar::Util::weaken ($menuitem);
  is ($toolitem, undef, 'toolitem - garbage collect when weakened');
  is ($menuitem, undef, 'menuitem - garbage collect when weakened');
}

#-----------------------------------------------------------------------------
# active-nick

{
  my $toolitem = Gtk2::Ex::ToolItem::ComboEnum->new
    (enum_type => 'My::Test1');
  is ($toolitem->get('active-nick'), undef, 'get(active-nick) initial');

  my $saw_notify;
  $toolitem->signal_connect ('notify::active-nick' => sub {
                               $saw_notify++;
                             });

  $saw_notify = 0;
  $toolitem->set (active_nick => 'quux');
  is ($saw_notify, 1, 'set_active_nick() notify');
  is ($toolitem->get('active-nick'), 'quux', 'set(active-nick) get()');

  $saw_notify = 0;
  $toolitem->set ('active-nick', 'foo');
  is ($saw_notify, 1, 'set(active-nick) notify');
  is ($toolitem->get('active-nick'), 'foo', 'set(active-nick) get()');

  $saw_notify = 0;
  $toolitem->set (active_nick => 'foo');
  is ($toolitem->get('active-nick'), 'foo', 'set(active-nick) get()');
}

#-----------------------------------------------------------------------------
# overflow menu

{
  my $toolitem = Gtk2::Ex::ToolItem::ComboEnum->new
    (enum_type => 'My::Test1');
  my $combobox = $toolitem->get_child;
  my $menuitem = $toolitem->retrieve_proxy_menu_item;
  isa_ok ($menuitem, 'Gtk2::MenuItem');  
  { my $m2 = $toolitem->retrieve_proxy_menu_item;
    is ($m2, $menuitem);
  }
  { my $m2 = $toolitem->retrieve_proxy_menu_item;
    is ($m2, $menuitem);
  }
  my $menu = $menuitem->get_submenu;
  isa_ok ($menu, 'Gtk2::Ex::Menu::EnumRadio');  

  is ($toolitem->get('active-nick'), undef);
  is ($combobox->get('active-nick'), undef);
  is ($menu->get('active-nick'), undef);

  $menu->set(active_nick => 'foo');
  is ($toolitem->get('active-nick'), 'foo');
  is ($combobox->get('active-nick'), 'foo');
  is ($menu->get('active-nick'), 'foo');
}


exit 0;
