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

require Gtk2::Ex::Menu::EnumRadio;

Glib::Type->register_enum ('My::Test1', 'foo', 'bar-ski', 'quux');

#------------------------------------------------------------------------------
# VERSION

my $want_version = 32;
{
  is ($Gtk2::Ex::Menu::EnumRadio::VERSION,
      $want_version,
      'VERSION variable');
  is (Gtk2::Ex::Menu::EnumRadio->VERSION,
      $want_version,
      'VERSION class method');

  ok (eval { Gtk2::Ex::Menu::EnumRadio->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::Menu::EnumRadio->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $menu = Gtk2::Ex::Menu::EnumRadio->new;
  is ($menu->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $menu->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $menu->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}


#-----------------------------------------------------------------------------
# property defaults





#-----------------------------------------------------------------------------
# Scalar::Util::weaken

{
  my $menu = Gtk2::Ex::Menu::EnumRadio->new;
  require Scalar::Util;
  Scalar::Util::weaken ($menu);
  is ($menu, undef, 'garbage collect when weakened');
}


#-----------------------------------------------------------------------------
# active-nick

{
  my $menu = Gtk2::Ex::Menu::EnumRadio->new
    (enum_type => 'My::Test1');
  is ($menu->get('active-nick'), undef, 'get(active-nick) initial');
  is ($menu->get_active_nick, undef, 'get_active_nick() initial');

  my $saw_notify;
  $menu->signal_connect ('notify::active-nick' => sub {
                           $saw_notify++;
                         });

  $saw_notify = 0;
  $menu->set_active_nick ('quux');
  is ($saw_notify, 1, 'set_active_nick() notify');
  is ($menu->get('active-nick'), 'quux', 'set_active_nick() get()');
  is ($menu->get_active_nick, 'quux', 'set_active_nick() get_active_nick()');

  $saw_notify = 0;
  $menu->set ('active-nick', 'foo');
  is ($saw_notify, 1, 'set(active-nick) notify');
  is ($menu->get('active-nick'), 'foo', 'set_active_nick() get()');
  is ($menu->get_active_nick, 'foo', 'set_active_nick() get_active_nick()');

  $saw_notify = 0;
  $menu->set_active_nick ('foo');
  is ($saw_notify, 0, 'set_active_nick() unchanged no notify');
  is ($menu->get('active-nick'), 'foo', 'set_active_nick() get()');
  is ($menu->get_active_nick, 'foo', 'set_active_nick() get_active_nick()');
}

#-----------------------------------------------------------------------------
# enum-type change

Glib::Type->register_enum ('MyTest::OneTwo', 'one', 'two');
Glib::Type->register_enum ('MyTest::ThreeFourTwo', 'three', 'four', 'two');

{
  my $menu = Gtk2::Ex::Menu::EnumRadio->new
    (enum_type => 'MyTest::ThreeFourTwo');
  {
    my @children = $menu->get_children;
    is (scalar(@children), 3);
    is_deeply ([map{$_->find_property('nick')&&$_->get('nick')} @children],
               ['three', 'four', 'two'],
               'enum-type initial nicks');
  }
  $menu->set (enum_type => 'MyTest::OneTwo');
  {
    my @children = $menu->get_children;
    is (scalar(@children), 2);
    is_deeply ([map{$_->find_property('nick')&&$_->get('nick')} @children],
               ['one','two'],
               'enum-type changed nicks');
  }
  $menu->prepend (Gtk2::MenuItem->new_with_label('Hello'));
  {
    my @children = $menu->get_children;
    is (scalar(@children), 3,
        'add extra item');
  }
  $menu->set (enum_type => 'MyTest::ThreeFourTwo');
  {
    my @children = $menu->get_children;
    is (scalar(@children), 4);
    is_deeply ([map{$_->find_property('nick')&&$_->get('nick')} @children],
               [undef,'three', 'four', 'two'],
               'enum-type change with extra item');
  }

  $menu->set_active_nick ('two');
  is ($menu->get_active_nick, 'two');
  $menu->set (enum_type => 'MyTest::OneTwo');
  is ($menu->get_active_nick, 'two');
  $menu->set (enum_type => 'MyTest::ThreeFourTwo');
  is ($menu->get_active_nick, 'two');

  $menu->set_active_nick ('four');
  is ($menu->get_active_nick, 'four');
  $menu->set (enum_type => 'MyTest::OneTwo');
  is ($menu->get_active_nick, undef);
  $menu->set (enum_type => 'MyTest::ThreeFourTwo');
  is ($menu->get_active_nick, undef);
}

exit 0;
