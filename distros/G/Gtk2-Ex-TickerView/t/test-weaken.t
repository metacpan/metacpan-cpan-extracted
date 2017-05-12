#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TickerView.
#
# Gtk2-Ex-TickerView is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-TickerView is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TickerView.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2::Ex::TickerView;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
use Test::Weaken::ExtraBits;

# Test::Weaken 2.002 for "ignore"
eval "use Test::Weaken 2.002;
      use Test::Weaken::Gtk2 24; # version 24 for contents_cell_renderers()
      1"
  or plan skip_all => "due to Test::Weaken 2.002 and/or Test::Weaken::Gtk2 not available -- $@";
diag ("Test::Weaken version ", Test::Weaken->VERSION);

plan tests => 5;

require Gtk2;
MyTestHelpers::glib_gtk_versions();


#-----------------------------------------------------------------------------

{
  my $leaks = Test::Weaken::leaks (sub { Gtk2::Ex::TickerView->new });
  is ($leaks, undef, 'deep garbage collection');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain $leaks;
  }
}

{
  my $leaks = Test::Weaken::leaks
    (sub {
       my $store = Gtk2::ListStore->new ('Glib::String');
       my $ticker = Gtk2::Ex::TickerView->new (model => $store);
       return [ $ticker, $store ];
     });
  is ($leaks, undef, 'deep garbage collection -- with a model set');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain $leaks;
  }
}

{
  my $leaks = Test::Weaken::leaks
    (sub {
       my $s1 = Gtk2::ListStore->new ('Glib::String');
       my $ticker = Gtk2::Ex::TickerView->new (model => $s1);
       my $s2 = Gtk2::ListStore->new ('Glib::String');
       $ticker->set (model => $s2);
       return [ $ticker, $s1, $s2 ];
     });
  is ($leaks, undef,
      'deep garbage collection -- with model set then changed to another');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain $leaks;
  }
}

#------------------------------------------------------------------------------
# timer run and stop

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;
diag "have_display: ",($have_display ? "yes" : "no");

sub my_ignore {
  my ($ref) = @_;
  return (Test::Weaken::ExtraBits::ignore_global_function($ref)
          || Test::Weaken::Gtk2::ignore_default_display($ref));
}

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 2;

  my $timer_running;

  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $store = Gtk2::ListStore->new ('Glib::String');
         $store->set ($store->append, 0 => 'foo');
         my $ticker = Gtk2::Ex::TickerView->new (model => $store,
                                                 width_request => 100,
                                                 height_request => 100);
         my $renderer = Gtk2::CellRendererText->new;
         $renderer->set (text => 'hello'); # dummy
         $ticker->pack_start ($renderer, 0);

         my $toplevel = Gtk2::Window->new ('toplevel');
         $toplevel->add ($ticker);
         $toplevel->show_all;
         MyTestHelpers::wait_for_event ($ticker, 'map-event');

         $timer_running = defined $ticker->{'timer'};
         return [ $toplevel, $ticker, $renderer, $store ];
       },
       destructor => \&Test::Weaken::Gtk2::destructor_destroy,
       contents => \&Test::Weaken::Gtk2::contents_cell_renderers,
       ignore => \&my_ignore,
     });
  ok ($timer_running, 'toplevel shown - timer runs');

  is ($leaks, undef, 'deep garbage collection -- running timer');
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
