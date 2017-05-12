#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
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

require Gtk2::Ex::ToolItem::CheckButton;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to Gtk2->init_check() unsuccessful';

# Test::Weaken 3 for "contents"
eval "use Test::Weaken 3; 1"
  or plan skip_all => "due to Test::Weaken 3 not available -- $@";

eval "use Test::Weaken::Gtk2; 1"
  or plan skip_all => "due to Test::Weaken::Gtk2 not available -- $@";

plan tests => 3;


{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         return Gtk2::Ex::ToolItem::CheckButton->new;
       },
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'plain');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $toolitem = Gtk2::Ex::ToolItem::CheckButton->new;
         my $menuitem_ref = \( $toolitem->retrieve_proxy_menu_item );
         return [ $toolitem, $menuitem_ref ];
       },
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'with menuitem');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $toolitem = Gtk2::Ex::ToolItem::CheckButton->new;
         my $menuitem1_ref = \($toolitem->retrieve_proxy_menu_item);
         my $menuitem2_ref = \($toolitem->retrieve_proxy_menu_item);
         return [ $toolitem, $menuitem1_ref, $menuitem2_ref ];
       },
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'with menuitem twice');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

exit 0;
