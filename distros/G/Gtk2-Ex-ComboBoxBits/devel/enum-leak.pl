#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Gtk2-Ex-ComboBoxBits.
#
# Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
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
use Gtk2::Ex::ComboBox::Enum;
use Gtk2 '-init';

# uncomment this to run the ### lines
use Smart::Comments;

Glib::Type->register_enum ('My::Test1', 'foo', 'bar-ski', 'quux',
                           100 .. 199);

{
  # leaks the menuitem in 2.22, even with ->destroy
  while (1) {
    my $toolitem = Gtk2::ToolButton->new (undef, 'Foo');
    #    my $menuitem =
    $toolitem->retrieve_proxy_menu_item;
    $toolitem->destroy;
  }
}

{
  my @leak;
  use Test::MemoryGrowth;
  no_growth {
    ### create
    #    push @leak,
    Gtk2::Ex::ComboBox::Enum->new (enum_type => 'My::Test1',
                                   active => 2);
  }
    calls => 10,
      'Constructing Gtk2::Ex::ComboBox::Enum does not grow memory';
  exit 0;
}

{
  while (1) {
    my $combo = Gtk2::Ex::ComboBox::Enum->new (enum_type => 'My::Test1',
                                               active => 2);
  }
}
