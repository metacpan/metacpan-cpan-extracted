#!/usr/bin/perl -w

#----------------------------------------------------------------------
# fileman.pl
#
# A file-manager example using GTK2::GladeXML.
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

use File::Spec; # portable path manipulations
use Gtk2 '-init'; # auto-initialize Gtk2
use Gtk2::GladeXML;
use Gtk2::SimpleList;   # easy wrapper for list views
use Gtk2::Gdk::Keysyms; # keyboard code constants

# Globals to track directories

my $home = $ENV{HOME};
my $cwd = '';
my $upd = ''; 
my ($file_count, $total_bytes); # used in status bar text

# Cached windows and other widgets

my $glade;
my $mainwin;
my $status;
my $preferences;
my $about;
my $fileview;
my $location;
my $diricon;
my $fileicon;


#----------------------------------------------------------------------
# Main program

# Load the UI from the Glade-2 file
$glade = Gtk2::GladeXML->new("fileman.glade");

# Connect signals magically
$glade->signal_autoconnect_from_package('main');

init_gui();

Gtk2->main; # Start Gtk2 main loop

# that's it!

exit 0;



#----------------------------------------------------------------------
sub init_gui {

    # connect a few widgets we'll access frequently

    $mainwin = $glade->get_widget('main');
    $location = $glade->get_widget('location_entry');
    $status = $glade->get_widget('statusbar');
    $preferences = $glade->get_widget('preferences');
    $about = $glade->get_widget('about');
    
    render_icons(2);
    my $size_sel = $glade->get_widget('size_options');
    $size_sel->set_history(2);

    # Connect glade-fileview to Gtk2::SimpleList
    
    my $widget = $glade->get_widget('fileview');
    $fileview = Gtk2::SimpleList->new_from_treeview(
        $widget,
        ''              => 'pixbuf',
        'File Name'     => 'text',
        'Size'          => 'text',
        'Type'          => 'text',
        'Date'          => 'text');
   
    # set some useful SimpleList properties
    
    $fileview->set_headers_clickable(1);
    foreach ($fileview->get_columns()) {
        $_->set_resizable(1);
        $_->set_sizing('grow-only');
    }
   
    # change to initial directory
    
    ch_dir($home);

    # set up a 'refresh' timer to check for new files
    
    Glib::Timeout->add(10000, 
        sub {
            my $index = ($widget->get_selected_indices())[0];
            refresh_fileview(); 
            $fileview->select($index) if defined $index;  # reset selection
            1; # 
        });
        
            
}

#----------------------------------------------------------------------
sub render_icons {
    my $sel = shift;

    my $size;
    $size = 'dialog'        if $sel == 0;
    $size = 'large-toolbar' if $sel == 1;
    $size = 'button'        if $sel == 2;
    $size = 'small-toolbar' if $sel == 3;
    $size = 'menu'          if $sel == 4;
    
    $diricon = $mainwin->render_icon('gtk-open', "$size"); 
    $fileicon = $mainwin->render_icon('gtk-new', "$size");
}

#----------------------------------------------------------------------
# Refreshes the file-view
#
sub refresh_fileview {

    @{$fileview->{data}} = ();
    
    opendir DIR, $cwd;
    my @all      = readdir DIR;
    closedir DIR;
   
    my @files    = grep { !/^\./ && -f "$cwd/$_"} @all;
    my @dirs     = grep { !/^\./ && -d "$cwd/$_"} @all;

    $file_count = $#files + $#dirs + 2;
    $total_bytes = 0;
    
    # Add directories to view
    foreach my $dir (@dirs) {
        my $time = localtime((stat("$cwd/$dir"))[9]);
        $total_bytes += 4096;
        push @{$fileview->{data}}, [$diricon, "$dir", "4096", "Folder", "$time"];   
    }

    # Add files to view 
    foreach my $file (@files) {
        my ($s, $t) = (stat("$cwd/$file"))[7,9];
        my $time = localtime($t);
        my $type;
        if ($file =~ m/.*\.(.*?)$/) {$type = $1}
        else {$type = 'Unknown';}
        $total_bytes += $s;
        push @{$fileview->{data}}, [$fileicon, "$file", "$s", "$type", "$time"];
    }

    # set a decent default selection (makes keyboard nav easy)
    $fileview->select(0);    

    
    # set up a 'refresh' timer to check for new files
    Glib::Timeout->add(100, 
        sub {
            my $context = $status->get_context_id('Main');
            $status->push($context, "$file_count files with $total_bytes bytes");
            0; # cancel timer
        });
}

#----------------------------------------------------------------------
# Change to parent directory
#
sub up_dir {
    my @dirs = File::Spec->splitdir ($cwd);
    pop @dirs;
    ch_dir(File::Spec->catdir(@dirs));
}

#----------------------------------------------------------------------
# Change the current working directory
#   * Updates file-view, location, and selection
#
sub ch_dir {
    my $newdir = File::Spec->canonpath (shift);

    return 0 unless -d $newdir; # only if it exists
    return 0 unless $newdir ne $cwd; # only on changes
    
    $cwd = $newdir;    
    refresh_fileview();
    $location->set_text($cwd);

    1;
}

#----------------------------------------------------------------------
# Signal handlers to match signals defined using Glade-2
#----------------------------------------------------------------------

# Some very simple handlers

sub on_home_button_clicked {ch_dir($home);}
sub on_back_button_clicked {up_dir();}
sub on_location_go_button_clicked {ch_dir($location->get_text());}
sub on_refresh_button_clicked {refresh_fileview();}
sub on_quit_activate {Gtk2->main_quit;}
sub on_prefs_button_clicked {$preferences->show_all;}
sub on_preferences_activate {$preferences->show_all;}
sub on_about_activate {$about->show_all;}
sub on_main_delete_event {Gtk2->main_quit;}
sub on_prefs_cancelbutton_clicked {$preferences->hide;}
sub on_about_okbutton_clicked {$about->hide;}

#----------------------------------------------------------------------
# Handle dialog 'close' (window-decoration induced close)
#   * Just hide the dialog, and tell Gtk not to do anything else
#
sub on_dialog_delete_event {
    my $w = shift; 
    $w->hide; 
    1; # consume this event!
}

#----------------------------------------------------------------------
# Handle preferencess apply click
#
sub on_prefs_applybutton_clicked {
    my $context = $status->get_context_id('Main');
    $status->push($context, 'Preferences updated');
}
    
#----------------------------------------------------------------------
# Handle prefs ok click (apply/dismiss dialog)
#
sub on_prefs_okbutton_clicked {
    on_prefs_applybutton_clicked();
    $preferences->hide;
}

#----------------------------------------------------------------------
# Handle key presses in location text edit control
#   * Translate a Return/Enter key into a 'Go' command
#   * All other key presses left for GTK
#
sub on_location_entry_key_release_event {
    my $widget = shift;
    my $event = shift;
    
    my $keypress = $event->keyval;    
    if ($keypress == $Gtk2::Gdk::Keysyms{KP_Enter} ||
        $keypress == $Gtk2::Gdk::Keysyms{Return}) {
        
        ch_dir($widget->get_text());
        
        return 1; # consume keypress
    }
        
    return 0; # let gtk have the keypress
}

#----------------------------------------------------------------------
# Handle keypress in file-veiw
#   * Translates backspace into a 'cd ..' command 
#   * All other key presses left for GTK
#
sub on_fileview_key_release_event {
    my $widget = shift;
    my $event = shift;
    
    if ($event->keyval == $Gtk2::Gdk::Keysyms{BackSpace}) {
        up_dir();
        return 1; # eat keypress
    }

    return 0; # let gtk have keypress

}

#----------------------------------------------------------------------
# Handle double-click (or enter) on file-view
#   * Translates into a 'cd <dir>' command
#
sub on_fileview_row_activated {
    my $widget = shift;

    my $index = ($widget->get_selected_indices())[0];
    ch_dir($cwd . '/' . $widget->{data}[$index][1]);

    return 1; # consume event
}

#----------------------------------------------------------------------
sub on_size_options_changed {
    my $widget = shift;
    render_icons($widget->get_history);
    return 0 unless defined $fileview; 
    refresh_fileview 
    $fileview->hide;
    $fileview->show;
    0;
}
