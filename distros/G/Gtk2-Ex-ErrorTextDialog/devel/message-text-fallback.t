#!/usr/bin/perl

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-ErrorTextDialog.
#
# Gtk2-Ex-ErrorTextDialog is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ErrorTextDialog is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ErrorTextDialog.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Test::More;

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin,
                           File::Spec->updir,'t',
                           'lib');
use MyTestHelpers;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;
if (! $have_display) {
  plan skip_all => "due to no DISPLAY available";
}
plan tests => 3;


#------------------------------------------------------------------------------
# _message_dialog_text_widget()

my $fake_text_property_called = 0;
{ my $real_find_property = \&Glib::Object::find_property;
  no warnings 'once';
  local *Gtk2::MessageDialog::find_property = sub {
    my ($obj, $pname) = @_;
    if ($pname eq 'text') {
      $fake_text_property_called++;
      return; # pretend doesn't exist
    } else {
      return $real_find_property->($obj, $pname);;
    }
  };
  require Gtk2::Ex::ErrorTextDialog;
}
is ($fake_text_property_called, 1,
    "fake find_property('text') called");

my $dialog = Gtk2::MessageDialog->new (undef, [], 'info', 'ok',
                                       'An informational message');

diag "call _message_dialog_set_text";
$fake_text_property_called = 0;
Gtk2::Ex::ErrorTextDialog::_message_dialog_set_text($dialog,'mess1');
is ($fake_text_property_called, 0,
    "fake find_property('text') not further called");

diag "call _message_dialog_set_text again";
$fake_text_property_called = 0;
Gtk2::Ex::ErrorTextDialog::_message_dialog_set_text($dialog,'mess2');
is ($fake_text_property_called, 0,
    "fake find_property('text') not further called");

$dialog->show_all;
main_iterations();
Glib::Timeout->add (2000, sub { Gtk2->main_quit;
                                return 0; # Glib::SOURCE_REMOVE
                              });
Gtk2->main;
$dialog->destroy;

exit 0;
