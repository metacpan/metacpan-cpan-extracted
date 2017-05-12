#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::DateSpinner::EntryWithCancel;

{
  my $foo = Gtk2::BindingSet->find
    ('Gtk2__Ex__DateSpinner__EntryWithCancel_keys');
  print "find ",($foo||'false'),"\n";
}

my $entry = Gtk2::Ex::DateSpinner::EntryWithCancel->new;

# bindingset comes into existence when a widget has gtksettings which ask
# the rc mechanism to parse its files
{
  my $foo = Gtk2::BindingSet->find
    ('Gtk2__Ex__DateSpinner__EntryWithCancel_keys');
  print "find ",($foo||'false'),"\n";
}

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->add($entry);

$entry->signal_connect (cancel => sub { print "cancel action runs\n"; });
$entry->bindings_activate (Gtk2::Gdk->keyval_from_name('Escape'),[]);


exit 0;
