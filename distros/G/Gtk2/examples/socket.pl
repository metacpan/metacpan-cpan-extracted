#!/usr/bin/perl -w

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

# this was originally gtk-2.2.1/examples/buttonbox/buttonbox.c
# ported to gtk2-perl by rm

use strict;
use Glib qw/TRUE FALSE/;
use Gtk2 -init;

my $pid;
my $socket;
my $win = Gtk2::Window->new("toplevel");
$win->set_default_size(640, 480);
$win->signal_connect( 'delete_event' => sub {
		Gtk2->main_quit;
		kill(2,$pid);
		1;
	});

$socket = Gtk2::Socket->new;
$win->add($socket);

printf("win: 0x%X\n", $socket->get_id);
$pid = fork;
if( $pid < 0 )
{
	die "there's a problem here, fork";
}
if( $pid == 0 )
{
	exec(sprintf("$^X plug.pl %d\n", $socket->get_id));
}

my $quitbtn = Gtk2::Button->new_from_stock('gtk-quit');
$quitbtn->signal_connect( 'clicked' => sub {
		Gtk2->main_quit;
		1;
	});

$socket->signal_connect('plug-removed' => sub {
		print STDERR "GtkPlug Disconnected\n";
		$win->remove($socket);
		$win->add($quitbtn);
		$win->set_border_width(50);
		$quitbtn->show;
		1;
	});

$win->show_all;

Gtk2->main;

waitpid($pid, 0);
