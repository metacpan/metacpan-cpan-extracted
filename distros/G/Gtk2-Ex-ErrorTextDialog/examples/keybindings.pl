#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

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


# Usage: ./keybindings.pl
#
# Customized key bindings for the action signals in an ErrorTextDialog can
# be made in the usual way.  It's as easy as putting a "binding" blob like
# below in your ~/.gtkrc-2.0 file, or programmatically with a Gtk2::Rc call
# as done here.
#
# Of course "clear" and "popup-save-dialog" aren't needed so often you'd
# really want extra key bindings for them, but the action signal + rc
# mechanism lets an application or user customize keys as desired.
#

use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::ErrorTextDialog;

Gtk2::Rc->parse_string (<<'HERE');

binding "my_error_keys" {
  bind "F5" { "popup-save-dialog" () }
  bind "F6" { "clear" () }
}
class "Gtk2__Ex__ErrorTextDialog" binding:application "my_error_keys"

HERE


my $errdialog = Gtk2::Ex::ErrorTextDialog->new;
$errdialog->signal_connect (destroy => sub { Gtk2->main_quit });

$errdialog->add_message ('This is an example of customized key bindings for action signals.');
$errdialog->add_message ('Press function key F5 for "popup-save-dialog".
Or press function key F6 to "clear" these messages!');
$errdialog->add_message ('These are in addition to the stock button mnemonics,
Alt-A for Save-As and Alt-C for Clear
(or whatever comes out in your locale).');

$errdialog->present;
Gtk2->main;
exit 0;
