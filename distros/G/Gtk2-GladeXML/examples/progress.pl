#!/usr/bin/perl -w

#----------------------------------------------------------------------
# progress.pl
#
# A simple example of Gtk2/GladeXML progress widgets
#
# Copyright (C) 2003 Bruce Alderson
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
# 
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#  
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the
#  Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#  Boston, MA 02111-1307, USA.
#
#----------------------------------------------------------------------

use strict;
use warnings;

use Gtk2 '-init'; # auto-initializes Gtk2
use Gtk2::GladeXML;

my $glade;
my $window;
my @progress; # array of progress widgets
my $fract = 0;


# Load the UI from the Glade-2 file
$glade = Gtk2::GladeXML->new("progress.glade");

# Connect the signal handlers
$glade->signal_autoconnect_from_package('main');

# Cache controls in perl-variables
$window = $glade->get_widget('main');
push @progress, $glade->get_widget('nw_progressbar');
push @progress, $glade->get_widget('ne_progressbar');
push @progress, $glade->get_widget('w_progressbar');
push @progress, $glade->get_widget('e_progressbar');
push @progress, $glade->get_widget('sw_progressbar');
push @progress, $glade->get_widget('se_progressbar');

# Start it up
Gtk2->main;

exit 0;


# Helper to update all of the progress widgets in one swoop
sub update_progress {
    foreach my $p (@progress) {
        $p->set_fraction($fract/1000);
    }
}

#----------------------------------------------------------------------
# Signal handlers, connected to signals we defined using glade-2 

# Handle next-button click: show next message
sub on_decrement_button_clicked {
    $fract -= 100; $fract %= 1001;
    update_progress;
}

# Handle previous-button click: show prev message
sub on_increment_button_clicked {
    $fract += 100; $fract %= 1001;
    update_progress;
}

# Set the formatting of the text on the scale widget
sub on_scale_format_value {
    my $pos = $_[1];
    return "$pos%";
}

# Handle movement of the scale slider
sub on_scale_value_changed {
    my $s = shift;
    $fract = $s->get_value * 10;
    update_progress;
}

# Handles window-manager-quit: shuts down gtk2 lib
sub on_main_delete_event {Gtk2->main_quit;}

# Handles close-button quit
sub on_quit_button_clicked {on_main_delete_event;}    

