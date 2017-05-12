#!/usr/bin/perl -w

#----------------------------------------------------------------------
#  clipboard.pl
#
#  A simple example of Gtk2/GladeXML Clipboard
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

# Load the UI from the Glade-2 file
my $glade = Gtk2::GladeXML->new("clipboard.glade");

# Connect the signal handlers
$glade->signal_autoconnect_from_package('main');

# Cache controls in perl-variables
my $editor = $glade->get_widget('textview1');
my $buffer = $editor->get_buffer();

my $clipboard = $editor->get_clipboard();

my $clipboard_buffer = $glade->get_widget('textview2')->get_buffer();

my $oldtext = '';

# Start it up
Gtk2->main;

exit 0;


#----------------------------------------------------------------------
# Signal handlers, connected to signals we defined using glade-2 


# Handle cut
sub on_cut1_activate
{
    $buffer->cut_clipboard($clipboard, 1);
}

# Handle copy
sub on_copy1_activate
{
    $buffer->copy_clipboard($clipboard);
}

# Handle paste
sub on_paste1_activate
{  
    $buffer->paste_clipboard($clipboard, undef, 1);
}

# Handle expose-event
# Refresh textview buffer if the clipboard has a new content
sub on_textview2_expose_event
{
    my $newtext = $clipboard->wait_for_text();
    if ($newtext ne $oldtext)
    {
        $clipboard_buffer->set_text($newtext);
        $oldtext = $newtext;
    }
}

# Handles window-manager-quit: shuts down gtk2 lib
sub on_quit1_activate {Gtk2->main_quit;}

sub on_main_delete_event {Gtk2->main_quit;}

