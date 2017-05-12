#!/usr/bin/perl

#
# GTK - The GIMP Toolkit
# Copyright (C) 1995-1997 Peter Mattis, Spencer Kimball and Josh MacDonald
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301, USA.
#
# $Id$
#

# based strongly on a script by gavin brown posted on the gtk-perl mailling
# list.

use Gtk2;
use strict;

Gtk2->init;

my $window = Gtk2::Window->new('toplevel');
$window->signal_connect('delete_event', sub { exit });

my @items = (
	[
		'/_Menu',
		undef,
		undef,
		undef,
		'<Branch>',
	],
	[
		'/_Menu/Run _Galeon',	# menu path
		'<ctrl>G',		# accel, see $accel_groups
		\&callback,		# callback func
		1,			# callback id
		'<StockItem>',		# type
		'gtk-execute'		# extra, in this case stock id
	],
	[
		'/_Menu/Run _Terminal',
		'<ctrl>T',
		sub { print STDERR "you found the magic menu item\n"; },
		2,
		'<StockItem>',
		'gtk-execute'
	],	[
		'/_Menu/Run GIM_P',
		undef,
		\&callback,
		3,
		'<StockItem>',
		'gtk-execute'
	],
	[
		'/_Menu/_Editors',
		undef,
		undef,
		undef,
		'<Branch>',
	],
	[
		'/_Menu/Editors/Run _Gedit',
		undef,
		\&callback,
		4,
		'<StockItem>',
		'gtk-execute'
	],
	[
		'/_Menu/Editors/Run _Emacs',
		undef,
		\&callback,
		5,
		'<StockItem>',
		'gtk-execute'
	],
	[
		'/_Menu/Editors/Run _nipples',
		'<ctrl>n',
		\&callback,
		6,
		'<StockItem>',
		'gtk-execute'
	],
);

use Data::Dumper;
sub callback
{
	print STDERR Dumper( @_ );
}

# create an accel group to catch our item's accelerators
my $accel_group = Gtk2::AccelGroup->new;

# create the factory, passing the accel_group
my $factory = Gtk2::ItemFactory->new('Gtk2::MenuBar', '<main>', $accel_group);

# pass the items, creating them.
$factory->create_items('foo', @items);

# get the root of the menu, widget, out of the factory
my $menu = $factory->get_widget('<main>');

$window->add($menu);

# add the accel group to the window so they can be caught.
$window->add_accel_group($accel_group);

$window->show_all;

Gtk2->main;
