#!/usr/bin/perl -w

#
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

use Gtk2 -init;

# how to set up accelerators by hand

sub cb_new   { warn "new\n" }
sub cb_open  { warn "open\n" }
sub cb_save  { warn "save\n" }
sub cb_close { warn "close\n"; Gtk2->main_quit; }
sub cb_cut   {
	warn "cut\n";
	my $n = 0;
	while ($accel_group->disconnect (\&cb_paste)) {
		$n++;
	}
	warn "   removed $n accelerators connected to cb_paste\n";
}
sub cb_copy  { warn "copy\n" }
sub cb_paste { warn "paste\n" }

@accels = (
	{ key => 'N', mod => 'control-mask', func => \&cb_new },
	{ key => 'O', mod => 'control-mask', func => \&cb_open },
	{ key => 'S', mod => 'control-mask', func => \&cb_save },
	{
		key => 'S',
		mod => [qw/control-mask shift-mask/],
	 	func => sub { warn "cb_save_as\n" },
	},
	{ key => 'W', mod => 'control-mask', func => 'cb_close' },
	{ key => 'X', mod => 'control-mask', func => 'cb_cut' },
	{ key => 'C', mod => 'control-mask', func => \&cb_copy },
	{ key => 'V', mod => 'control-mask', func => \&cb_paste },
	{ key => 'F3', mod => [], func => \&cb_paste },
	{ key => 'equal', mod => [], func => sub { warn "zoom in\n"} },
	{ key => 'minus', mod => [], func => sub { warn "zoom out\n"} },
);

$accel_group = Gtk2::AccelGroup->new;

use Gtk2::Gdk::Keysyms;
foreach my $a (@accels) {
	$accel_group->connect ($Gtk2::Gdk::Keysyms{$a->{key}}, $a->{mod},
	                       'visible', $a->{func});
}

$window = Gtk2::Window->new;
$window->add_accel_group ($accel_group);
$window->signal_connect (delete_event => sub {Gtk2->main_quit; 1});
$window->show_now;
Gtk2->main;
undef $accel_group;
undef $window;
