#!/usr/bin/perl

use strict;
use warnings;
use Gtk2::Ex::Spinner::EntryWithCancel;
use Test::More tests => 22;

SKIP: { eval 'use Test::NoWarnings; 1'
          or skip 'Test::NoWarnings not available', 1; }

my $want_version = 5.1;
ok ($Gtk2::Ex::Spinner::EntryWithCancel::VERSION >= $want_version,
    'VERSION variable');
ok (Gtk2::Ex::Spinner::EntryWithCancel->VERSION >= $want_version,
    'VERSION class method');
ok (eval { Gtk2::Ex::Spinner::EntryWithCancel->VERSION($want_version); 1 },
    "VERSION class check $want_version");
{ my $check_version = $want_version + 1000;
  ok (! eval{Gtk2::Ex::Spinner::EntryWithCancel->VERSION($check_version); 1},
      "VERSION class check $check_version");
}

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

SKIP: {
  # seem to need a DISPLAY initialized in gtk 2.16 or get a slew of warnings
  # creating a Gtk2::Ex::Spinner::EntryWithCancel
  $have_display or skip "due to no DISPLAY available", 2;

  # check the once-only rc bits are ok
  ok (Gtk2::Ex::Spinner::EntryWithCancel->new,
      'create 1');

  my $init = \&Gtk2::Ex::Spinner::EntryWithCancel::INIT_INSTANCE;
  is ($init, \&Glib::FALSE,
      'INIT_INSTANCE once-only rc bits');
}

SKIP: {
  $have_display or skip "due to no DISPLAY available", 15;

  my $entry = Gtk2::Ex::Spinner::EntryWithCancel->new;

  ok ($entry->VERSION >= $want_version, 'VERSION object method');
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
