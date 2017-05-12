#!/usr/bin/perl -w

# GTK - The GIMP Toolkit
# Copyright (C) 1995-1997 Peter Mattis, Spencer Kimball and Josh MacDonald
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

# this was originally gtk-2.2.1/examples/buttonbox/buttonbox.c
# ported to gtk2-perl by rm

use strict;

use Gtk2;

die "ERROR: give me a socket" unless( scalar($ARGV[0]) );

sleep(1);

Gtk2->init;

printf("socket_id: %X\n", $ARGV[0]);
my $plug = Gtk2::Plug->new($ARGV[0]);
$plug->set_border_width(10);

my $hbox = Gtk2::HBox->new(0,5);
$plug->add($hbox);

my $state = 1;
my $img = Gtk2::Image->new_from_stock("gtk-yes", "dialog");
$hbox->pack_start($img, 1, 1, 5);

my $vbox = Gtk2::VBox->new(0,5);
$hbox->pack_start($vbox, 1, 1, 5);

my $btn = Gtk2::Button->new("Click me before exiting!");
$vbox->pack_start($btn, 1, 1, 5);

$btn->signal_connect( "clicked" => sub {
		Gtk2->main_quit;
	});

my @array = ( $img, $state );
foreach (1..5)
{
	my $btn = Gtk2::Button->new("Just a button $_");
	$vbox->pack_start($btn, 1, 1, 5);
	$btn->signal_connect( "clicked" => sub {
			print STDERR 'btn: '.$_[0]->get_label.' state: '.
				$_[1][1]." \n";
			if( $_[1][1] )
			{
				$_[1][0]->set_from_stock('gtk-no', 'dialog');
				$_[1][1] = 0;
			}
			else
			{
				$_[1][0]->set_from_stock('gtk-yes', 'dialog');
				$_[1][1] = 1;
			}
		}, \@array
	);
}

$plug->show_all;

Gtk2->main;
