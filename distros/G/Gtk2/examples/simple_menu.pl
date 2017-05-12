#!/usr/bin/perl -w 

# Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the full
# list)
# 
# This library is free software; you can redistribute it and/or modify it under
# the terms of the GNU Library General Public License as published by the Free
# Software Foundation; either version 2.1 of the License, or (at your option)
# any later version.
# 
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Library General Public License for
# more details.
# 
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.
#
# $Id$
#
# r.m.
# 

use strict;
use Gtk2 '-init';
use Gtk2::SimpleMenu;
use Data::Dumper;

sub callback
{
	print "Callback:\n";
	print Dumper(@_);
}

sub default_callback
{
	print "Default Callback:\n";
	print Dumper(@_);
}

my $action = 0;
my $menu_tree = [
	_File  => {
		item_type  => '<Branch>',
		children => [
			_New       => {
				callback => \&callback,
				callback_action => $action++,
				accelerator => '<ctrl>N',
			},
			_Save      => {
				callback_action => $action++,
				callback_data => 'cbdata 1',
				accelerator => '<ctrl>S',
			},
			'Save _As' => {
				callback => \&callback,
				callback_action => $action++,
				callback_data => 'cbdata 2',
				accelerator => '<ctrl>A',
			},
			_Exit      => {
				callback => sub { Gtk2->main_quit; },
				callback_action => $action++,
				accelerator => '<ctrl>E',
			},
		],
	},
	_Edit  => {
		item_type => '<Branch>',
		children => [
			_Copy  => {
				callback => \&callback,
				callback_action => $action++,
			},
			_Paste => {
				callback_action => $action++,
			},
		],
	},
	_Tools => {
		item_type => '<Branch>',
		children => [
			_Tearoff => {
				item_type => '<Tearoff>',
			},
			_CheckItem => {
				callback => \&callback,
				callback_action => $action++,
				item_type => '<CheckItem>',
			},
			_ToggleItem => {
				callback_action => $action++,
				item_type => '<ToggleItem>',
			},
			_StockItem => {
				callback => \&callback,
				callback_action => $action++,
				item_type => '<StockItem>',
				extra_data => 'gtk-execute',
			},
			_Radios => {
				item_type => '<Branch>',
				children => [
					'Radio _1' => {
						callback => \&callback,
						callback_action => $action++,
						item_type  => '<RadioItem>',
						groupid => 1,
					},
					'Radio _2' => {
						callback => \&callback,
						callback_action => $action++,
						item_type  => '<RadioItem>',
						groupid => 1,
					},
					'Radio _3' => {
						callback => \&callback,
						callback_action => $action++,
						item_type  => '<RadioItem>',
						groupid => 1,
					},
				],
			},
			Separator => {
				item_type => '<Separator>',
			},
#			image menu item types are not supported at this point
#			_Image => {
#				callback => \&callback,
#				callback_action => $action++,
#				item_type => '<ImageItem>',
#			},
		],
	},
	_Help  => {
		item_type => '<Branch>',
		children => [
			_Introduction => {
				callback => \&callback,
				callback_action => $action++,
			},
			_About        => {
				callback_action => $action++,
			}
		],
	},
];

my $menu = Gtk2::SimpleMenu->new(
				menu_tree        => $menu_tree,
				default_callback => \&default_callback,
				user_data        => 'user data',
			);

$menu->get_widget('/Tools/Radios/Radio 2')->set_active(1);

my $win = Gtk2::Window->new;
$win->signal_connect(delete_event => sub { exit });
$win->add($menu->{widget});
$win->add_accel_group($menu->{accel_group});
$win->show_all;
Gtk2->main;

