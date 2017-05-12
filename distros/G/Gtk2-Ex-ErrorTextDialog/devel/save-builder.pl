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


# Making a SaveDialog with the builder mechanism misses the setups in the
# subclassed new() ...
#

use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::ErrorTextDialog::SaveDialog;

my $builder = Gtk2::Builder->new;
$builder->add_from_string ('
<interface>
  <object class="Gtk2__Ex__ErrorTextDialog__SaveDialog" id="my-save-dialog">
  </object>
</interface>
');

sub do_quit { Gtk2->main_quit; }
$builder->connect_signals;

my $dialog = $builder->get_object('my-save-dialog');
print $dialog->get_action,"\n";

$dialog->show;
Gtk2->main;
exit 0;
