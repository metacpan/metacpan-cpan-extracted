#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-MenuView.
#
# Gtk2-Ex-MenuView is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-MenuView is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-MenuView.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2::Ex::MenuView;
use Test::More;

use lib 't';
use MyTestHelpers;

# Test::Weaken 3 for "contents"
my $have_test_weaken = eval "use Test::Weaken 3;
                             use Test::Weaken::Gtk2;
                             1";
if (! $have_test_weaken) {
  plan skip_all => "due to Test::Weaken 3 and/or Test::Weaken::Gtk2 not available -- $@";
}
diag ("Test::Weaken version ", Test::Weaken->VERSION);

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;
if (! $have_display) {
  plan skip_all => "due to no DISPLAY";
}

plan tests => 5;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

MyTestHelpers::glib_gtk_versions();

sub my_contents {
  my ($ref) = @_;
  return (Test::Weaken::Gtk2::contents_container($ref),
          Test::Weaken::Gtk2::contents_submenu($ref));
}

#-----------------------------------------------------------------------------

{
  my $leaks = Test::Weaken::leaks (sub { Gtk2::Ex::MenuView->new });
  is ($leaks, undef, 'deep garbage collection');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain $leaks;
  }
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $store = Gtk2::ListStore->new ('Glib::String');
         my $menuview = Gtk2::Ex::MenuView->new (model => $store);
         return [ $menuview, $store ];
       },
       contents => \&my_contents,
     });
  is ($leaks, undef, 'deep garbage collection -- with a model set');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain $leaks;
  }
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $s1 = Gtk2::ListStore->new ('Glib::String');
         my $menuview = Gtk2::Ex::MenuView->new (model => $s1);
         my $s2 = Gtk2::ListStore->new ('Glib::String');
         $menuview->set (model => $s2);
         return [ $menuview, $s1, $s2 ];
       },
       contents => \&my_contents,
     });
  is ($leaks, undef,
      'deep garbage collection -- with model set then changed to another');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain $leaks;
  }
}

{
  my $child_count;
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $store = Gtk2::ListStore->new ('Glib::String');
         $store->set ($store->append, 0 => 'foo');
         $store->set ($store->append, 0 => 'bar');
         my $menuview = Gtk2::Ex::MenuView->new (model => $store);
         $menuview->signal_connect
           (item_create_or_update => sub {
              my ($menuview, $item, $model, $path, $iter) = @_;
              diag "create ",$path->to_string;
              $item = Gtk2::MenuItem->new_with_label ($model->get($iter,0));
              $item->show;
              return $item;
            });
         $menuview->popup (undef, undef, undef, undef, 1, 0);
         # Gtk2->main;
         MyTestHelpers::wait_for_event ($menuview, 'map-event');
         $child_count = scalar @{[$menuview->get_children]};
         return [ $menuview, $store ];
       },
       destructor => sub {
         my ($aref) = @_;
         my $menuview = $aref->[0];
         $menuview->popdown;
       },
       contents => \&my_contents,
     });

  is ($child_count, 2, 'deep garbage collection -- popup, child count');
  is ($leaks, undef, 'deep garbage collection -- popup');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain $leaks;

    my $unfreed = $leaks->unfreed_proberefs;
    foreach my $proberef (@$unfreed) {
      diag "  unfreed $proberef";
    }
    foreach my $proberef (@$unfreed) {
      diag "  search $proberef";
      MyTestHelpers::findrefs($proberef);
    }
  }
}

exit 0;
