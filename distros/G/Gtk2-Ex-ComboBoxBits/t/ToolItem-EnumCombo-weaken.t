#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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
use Test::More;

use lib 't';
use MyTestHelpers;
use Test::Weaken::ExtraBits;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::ToolItem::ComboEnum;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';

# Test::Weaken 3 for "contents"
eval "use Test::Weaken 3; 1"
  or plan skip_all => "due to Test::Weaken 3 not available -- $@";

eval "use Test::Weaken::Gtk2; 1"
  or plan skip_all => "due to Test::Weaken::Gtk2 not available -- $@";

plan tests => 3;

sub my_contents {
  my ($ref) = @_;
  return (Test::Weaken::Gtk2::contents_container($ref),
          Test::Weaken::Gtk2::contents_submenu($ref));
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         return Gtk2::Ex::ToolItem::ComboEnum->new;
       },
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'plain');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $toolitem = Gtk2::Ex::ToolItem::ComboEnum->new;
         my $menuitem = $toolitem->retrieve_proxy_menu_item;
         return [ $toolitem, $menuitem ];
       },
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'with menuitem');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $toolitem = Gtk2::Ex::ToolItem::ComboEnum->new;
         my $menuitem1 = $toolitem->retrieve_proxy_menu_item;
         my $menuitem2 = $toolitem->retrieve_proxy_menu_item;
         return [ $toolitem, $menuitem1, $menuitem2 ];
       },
       contents => \&my_contents,
     });
  is ($leaks, undef, 'with menuitem twice');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

exit 0;
