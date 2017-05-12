#!/usr/bin/perl

# Copyright 2008, 2009, 2010, 2011, 2013 Kevin Ryde

# This file is part of Gtk2-Ex-DateSpinner.
#
# Gtk2-Ex-DateSpinner is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-DateSpinner is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-DateSpinner.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::Entry::WithCancel;

# seem to need a DISPLAY initialized in gtk 2.16 or get a slew of warnings
# creating a Gtk2::Ex::Entry::WithCancel
Gtk2->init_check
  or plan skip_all => "due to no DISPLAY available";

plan tests => 20;

my $want_version = 9;
{
  is ($Gtk2::Ex::Entry::WithCancel::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::Entry::WithCancel->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { Gtk2::Ex::Entry::WithCancel->VERSION($want_version); 1 },
      "VERSION class check $want_version");

  my $check_version = $want_version + 1000;
  ok (! eval{Gtk2::Ex::Entry::WithCancel->VERSION($check_version); 1},
      "VERSION class check $check_version");
}

{
  # check the once-only rc bits are ok
  ok (Gtk2::Ex::Entry::WithCancel->new,
      'create 1');

  # took this away in favour of just Gtk2::Rc at load-time ...
  #   my $init = \&Gtk2::Ex::Entry::WithCancel::INIT_INSTANCE;
  #   is ($init, \&Glib::FALSE,
  #       'INIT_INSTANCE once-only rc bits');
}

{
  my $entry = Gtk2::Ex::Entry::WithCancel->new;

  is ($entry->VERSION, $want_version, 'VERSION object method');
  ok (eval { $entry->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $entry->VERSION($check_version); 1 },
      "VERSION object check $check_version");

  $entry->set('editing-cancelled', 1);
  $entry->activate;
  ok (! $entry->get('editing-cancelled'),
      'activate() not a cancel');

  ok ($entry->signal_query ('cancel'),
      'cancel signal exists');

  $entry->set('editing-cancelled', 0);
  $entry->cancel;
  ok ($entry->get('editing-cancelled'),
      'cancel() sets cancelled flag');

  $entry->set('editing-cancelled', 0);
  $entry->signal_emit ('cancel');
  ok ($entry->get('editing-cancelled'),
      'cancel signal sets cancelled flag');

  my $saw_editing_done;
  $entry->signal_connect (editing_done => sub { $saw_editing_done = 1 });
  my $saw_remove_widget;
  $entry->signal_connect (remove_widget => sub { $saw_remove_widget = 1 });

  $entry->start_editing (undef);
  $saw_editing_done = 0;
  $saw_remove_widget = 0;
  $entry->set('editing-cancelled', 1);
  $entry->activate;
  is ($saw_editing_done, 1,
      'activate during editing emits editing-done');
  is ($saw_editing_done, 1,
      'activate during editing emits remove-widget');
  ok (! $entry->get('editing-cancelled'),
      'activate during editing clears editing-cancelled property');


  $entry->start_editing (undef);
  $saw_editing_done = 0;
  $saw_remove_widget = 0;
  $entry->set('editing-cancelled', 0);
  $entry->cancel;
  is ($saw_editing_done, 1,
      'cancel during editing emits editing-done');
  is ($saw_editing_done, 1,
      'cancel during editing emits remove-widget');
  ok ($entry->get('editing-cancelled'),
      'cancel during editing sets editing-cancelled property');

  $saw_editing_done = 0;
  $saw_remove_widget = 0;
  $entry->cancel;
  is ($saw_editing_done, 0,
      "cancel outside editing doesn't emit editing-done");
  is ($saw_editing_done, 0,
      "cancel outside editing doesn't emit remove-widget");
}

exit 0;
