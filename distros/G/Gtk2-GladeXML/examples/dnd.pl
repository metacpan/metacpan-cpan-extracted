#!/usr/bin/perl -w

#----------------------------------------------------------------------
#  dnd.pl
#
#  A simple example of Gtk2/GladeXML Dnd
#
#  Copyright (C) 2004 Fabrice Duballet
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

#----------------------------------------------------------------------
# GNU Licenses :

my @t = gmtime;
my $year = $t[5] + 1900;

my $author = "Name of Author";

my $copyright = "    Copyright (C) $year ";

#GNU General Public License
my $gpl = "\n
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
    \n";

#GNU Lesser General Public License
my $lgpl = "\n
    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
    \n";
 
#GNU Free Documentation License
my $fdl = "\n
    Permission is granted to copy, distribute and/or modify this document
    under the terms of the GNU Free Documentation License, Version 1.2
    or any later version published by the Free Software Foundation;
    with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
    A copy of the license is included in the section entitled \"GNU
    Free Documentation License\".
    \n";
    
sub gnulicense {return $copyright.$author.shift}

#----------------------------------------------------------------------
# Gtk2 Glade-2 :

# Load the UI from the Glade-2 file
my $glade = Gtk2::GladeXML->new("dnd.glade");

# Connect the signal handlers
$glade->signal_autoconnect_from_package('main');

use constant  TARGET_STRING => 0;

my @target_table = (
    {'target' => "STRING", 'flags' => [], 'info' => TARGET_STRING},
    {'target' => "text/plain", 'flags' => [], 'info' => TARGET_STRING}
);
    
my $buttongpl  = $glade->get_widget('buttongpl');
my $buttonlgpl = $glade->get_widget('buttonlgpl');
my $buttonfdl  = $glade->get_widget('buttonfdl');
my $buttondrop = $glade->get_widget('buttondrop');

$buttongpl->drag_source_set  (['button1_mask', 'button3_mask'], ['copy', 'move'], @target_table);
$buttonlgpl->drag_source_set (['button1_mask', 'button3_mask'], ['copy', 'move'], @target_table);
$buttonfdl->drag_source_set  (['button1_mask', 'button3_mask'], ['copy', 'move'], @target_table);

$buttondrop->drag_dest_set('all', ['copy', 'move'], @target_table);

# Start it up
Gtk2->main;

exit 0;


#----------------------------------------------------------------------
# Signal handlers, connected to signals we defined using glade-2 

sub on_buttongpl_drag_data_get
{
    my ($widget, $context, $data, $info, $time) = @_;
    $data->set($data->target, 8, gnulicense($gpl));
}

sub on_buttonlgpl_drag_data_get
{
    my ($widget, $context, $data, $info, $time) = @_;
    $data->set($data->target, 8, gnulicense($lgpl));
}

sub on_buttonfdl_drag_data_get
{
    my ($widget, $context, $data, $info, $time) = @_;
    $data->set($data->target, 8, gnulicense($fdl));
}

sub on_buttondrop_drag_data_received
{
    my ($widget, $context, $x, $y, $data, $info, $time) = @_;
    if (($data->length >= 0) && ($data->length < 80) && ($data->format == 8))
    {
        $author = $data->data;
        $context->finish (1, 0, $time);
        return;
    }
    $context->finish(0, 0, $time);
}

sub on_main_delete_event {Gtk2->main_quit;}
