#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Gtk2-Ex-ComboBoxBits.
#
# Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ComboBoxBits.  If not, see <http://www.gnu.org/licenses/>.


use 5.010;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::ComboBoxBits;

my $model = Gtk2::TreeStore->new ('Glib::String');
$model->insert (undef, 0);
$model->insert (undef, 1);
$model->insert (undef, 2);
$model->insert ($model->iter_nth_child(undef,2), 0);
$model->insert ($model->iter_nth_child(undef,2), 1);

my $combobox = Gtk2::ComboBox->new;
$combobox->signal_connect (notify => sub {
                             my ($combobox, $pspec) = @_;
                             my $pname = $pspec->get_name;
                             say "notify $pname now ",$combobox->get($pname);
                             say "   get(active) ",$combobox->get('active');
                           });
# $combobox->set('active',3,
#                model => $model);
$combobox->set_active(3);
$combobox->set_model($model);
say "get(active) ",$combobox->get('active');

# $combobox->set_model ($model);

# is (get_active_path($combobox), undef);
# is (find_text_iter($combobox, 'nosuchentry'), undef);
#
# set_active_path($combobox,Gtk2::TreePath->new_from_indices(0,0));
# set_active_text($combobox,'nosuchentry');
# ok(1);

exit 0;
