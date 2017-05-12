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


use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::ErrorTextDialog;
use Gtk2::Ex::ErrorTextDialog::SaveDialog;

my $dialog = Gtk2::Ex::ErrorTextDialog->instance;
$dialog->add_message("\
hello
fdjsk
fsdjkl
\x{C1}

fsdjk fkjsd kfj sdk
ksdjfksdksdjf s
");
Gtk2::Ex::ErrorTextDialog::SaveDialog::_save_to_filename($dialog,'/tmp/x.utf8');
exit 0;
