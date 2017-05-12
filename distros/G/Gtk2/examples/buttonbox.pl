#!/usr/bin/perl -w

#
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
# $Id$
#

# this was originally gtk-2.2.1/examples/buttonbox/buttonbox.c
# ported to gtk2-perl by rm

use strict;
use Glib qw(TRUE FALSE);
use Gtk2 -init;

# Create a Button Box with the specified parameters
sub create_bbox
{
	my $horizontal = shift;
	my $title = shift;
	my $spacing = shift;
	my $child_w = shift;
	my $child_h = shift;
	my $layout = shift;

	my $frame = Gtk2::Frame->new($title);
	my $bbox;

	if( $horizontal )
	{
		$bbox = Gtk2::HButtonBox->new;
	}
	else
	{
		$bbox = Gtk2::VButtonBox->new;
	}

	$bbox->set_border_width(5);
	$frame->add($bbox);

	# Set the appearance of the Button Box
	$bbox->set_layout($layout);
	$bbox->set_spacing($spacing);
	#gtk_button_box_set_child_size (GTK_BUTTON_BOX (bbox), child_w, child_h);

	my $button = Gtk2::Button->new_from_stock('gtk-ok');
	$button->signal_connect( 'clicked' => sub { 
			print "$title ok clicked\n"; } );
	$bbox->add($button);

	$button = Gtk2::Button->new_from_stock('gtk-cancel');
	$button->signal_connect( 'clicked' => sub { 
			print "$title cancel clicked\n"; } );
	$bbox->add($button);

	$button = Gtk2::Button->new_from_stock('gtk-help');
	$button->signal_connect( 'clicked' => sub { 
			print "$title help clicked\n"; } );
	$bbox->add($button);

  	return($frame);
}

# Initialize GTK
Gtk2->init;

my $window = Gtk2::Window->new("toplevel");
$window->set_title("Button Boxes");

$window->signal_connect( "destroy" => sub {
		Gtk2->main_quit;
	});

$window->set_border_width(10);

my $main_vbox = Gtk2::VBox->new("false", 0);
$window->add($main_vbox);

my $frame_horz = Gtk2::Frame->new("Horizontal Button Boxes");
$main_vbox->pack_start($frame_horz, TRUE, TRUE, 10);

my $vbox = Gtk2::VBox->new(FALSE, 0);
$vbox->set_border_width(10);
$frame_horz->add($vbox);

$vbox->pack_start(
	create_bbox(TRUE, 'Spread (spacing 40)', 40, 85, 20, 'spread'),
	TRUE, TRUE, 0);

$vbox->pack_start(
	create_bbox(TRUE, 'Edge (spacing 30)', 30, 85, 20, 'edge'),
	TRUE, TRUE, 5);

$vbox->pack_start(
	create_bbox(TRUE, 'Start (spacing 20)', 20, 85, 20, 'start'),
	TRUE, TRUE, 5);

$vbox->pack_start(
	create_bbox(TRUE, 'End (spacing 10)', 10, 85, 20, 'end'),
	TRUE, TRUE, 5);

my $frame_vert = Gtk2::Frame->new("Vertical Button Boxes");
$main_vbox->pack_start($frame_vert, TRUE, TRUE, 10);


my $hbox = Gtk2::HBox->new(FALSE, 0);
$hbox->set_border_width(10);
$frame_vert->add($hbox);

$hbox->pack_start(
	create_bbox(FALSE, 'Spread (spacing 5)', 5, 85, 20, 'spread'),
	TRUE, TRUE, 0);

$hbox->pack_start(
	create_bbox(FALSE, 'Edge (spacing 30)', 30, 85, 20, 'edge'),
	TRUE, TRUE, 0);

$hbox->pack_start(
	create_bbox(FALSE, 'Start (spacing 20)', 20, 85, 20, 'start'),
	TRUE, TRUE, 0);

$hbox->pack_start(
	create_bbox(FALSE, 'End (spacing 20)', 20, 85, 20, 'end'),
	TRUE, TRUE, 0);

$window->show_all;

# Enter the event loop
Gtk2->main;

exit 0;
