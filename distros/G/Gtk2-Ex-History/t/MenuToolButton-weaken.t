#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-History.
#
# Gtk2-Ex-History is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
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
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# Test::Weaken 3 for "contents"
eval "use Test::Weaken 3; 1"
  or plan skip_all => "Test::Weaken 3 not available -- $@";

require Gtk2::Ex::History;
require Gtk2::Ex::History::MenuToolButton;

require Gtk2;
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';
plan tests => 3;

require Test::Weaken::Gtk2;

sub my_contents {
  my ($ref) = @_;
  return (Test::Weaken::Gtk2::contents_container ($ref),
          Test::Weaken::Gtk2::contents_submenu ($ref));
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         return Gtk2::Ex::History::MenuToolButton->new;
       },
       contents => \&my_contents,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection, no history');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $history = Gtk2::Ex::History->new;
         my $item = Gtk2::Ex::History::MenuToolButton->new (history=>$history);
         return [ $item, $history ];
       },
       contents => \&my_contents,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection, with history');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $history = Gtk2::Ex::History->new;
         my $item = Gtk2::Ex::History::MenuToolButton->new (history => $history);
         my $menu1 = $item->get_menu;
         # diag $menu1;
         $item->signal_emit ('show-menu');
         # diag $item->get_menu;
         return [ $item, $history, $menu1 ];
       },
       destructor => \&Test::Weaken::Gtk2::destructor_destroy,
       contents => \&my_contents,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection, history and show-menu');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

exit 0;
