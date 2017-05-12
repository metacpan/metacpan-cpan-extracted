#
# Change Display
# 
# Demonstrates migrating a window between different displays and
# screens. A display is a mouse and keyboard with some number of
# associated monitors. A screen is a set of monitors grouped
# into a single physical work area. The neat thing about having
# multiple displays is that they can be on a completely separate
# computers, as long as there is a network connection to the
# computer where the application is running.
#
# Only some of the windowing systems where GTK+ runs have the
# concept of multiple displays and screens. (The X Window System
# is the main example.) Other windowing systems can only
# handle one keyboard and mouse, and combine all monitors into
# a single screen.
#
# This is a moderately complex example, and demonstrates:
#
#  - Tracking the currently open displays and screens
#
#  - Changing the screen for a window
#
#  - Letting the user choose a window by clicking on it
# 
#  - Using GtkListStore and GtkTreeView
#
#  - Using GtkDialog
#

package changedisplay;

use Glib qw(TRUE FALSE);
use Gtk2;


#include <string.h>
#include <gtk/gtk.h>
#include "demo-common.h"

##
## The ChangeDisplayInfo structure corresponds to a toplevel window and
## holds pointers to widgets inside the toplevel window along with other
## information about the contents of the window.
## This is a common organizational structure in real applications.
##
#typedef struct _ChangeDisplayInfo ChangeDisplayInfo;
#
#struct _ChangeDisplayInfo
#{
#  GtkWidget *window;
#  GtkSizeGroup *size_group;
#
#  GtkTreeModel *display_model;
#  GtkTreeModel *screen_model;
#  GtkTreeSelection *screen_selection;
#  
#  GdkDisplay *current_display;
#  GdkScreen *current_screen;
#};

#
# These enumerations provide symbolic names for the columns
# in the two GtkListStore models.
#
use constant DISPLAY_COLUMN_NAME    => 0;
use constant DISPLAY_COLUMN_DISPLAY => 1;
use constant DISPLAY_NUM_COLUMNS    => 2;

use constant SCREEN_COLUMN_NUMBER => 0;
use constant SCREEN_COLUMN_SCREEN => 1;
use constant SCREEN_NUM_COLUMNS   => 2;

#
# Finds the toplevel window under the mouse pointer, if any.
#
sub find_toplevel_at_pointer {
  my $display = shift;

#  my $pointer_window = $display->get_window_at_pointer;
  use Data::Dumper;
  my ($pointer_window, undef, undef) = $display->get_window_at_pointer;

  #
  # The user data field of a GdkWindow is used to store a pointer
  # to the widget that created it.
  #
  if ($pointer_window) {
    my $ptr = $pointer_window->get_user_data;
    if ($ptr) {
      my $widget = Glib::Object->new_from_pointer ($ptr);
      return $widget ? $widget->get_toplevel : undef;
    } else {
      return undef;
    }
  } else {
    return undef;
  }
}

sub button_release_event_cb {
#  my ($widget, $event, $clicked_ref) = @_;
  my (undef, undef, $clicked_ref) = @_;
  $$clicked_ref = TRUE;
  return TRUE;
}

#
# Asks the user to click on a window, then waits for them click
# the mouse. When the mouse is released, returns the toplevel
# window under the pointer, or NULL, if there is none.
#
sub query_for_toplevel {
  my ($screen, $prompt) = @_;

  my $display = $screen->get_display;
  my $toplevel = undef;
  
  my $popup = Gtk2::Window->new ('popup');
  $popup->set_screen ($screen);
  $popup->set_modal (TRUE);
  $popup->set_position ('center');
  
  my $frame = Gtk2::Frame->new;
  $frame->set_shadow_type ('out');
  $popup->add ($frame);
  
  my $label = Gtk2::Label->new ($prompt);
  $label->set_padding (10, 10);
  $frame->add ($label);
  
  $popup->show_all;
  my $cursor = Gtk2::Gdk::Cursor->new_for_display ($display, 'crosshair');
  
  if (Gtk2::Gdk->pointer_grab ($popup->window, FALSE,
                               'button-release-mask',
                               undef,
                               $cursor,
                               0) eq 'success') #'GDK_GRAB_SUCCESS')
    {
      my $clicked = FALSE;

      $popup->signal_connect (button_release_event => \&button_release_event_cb, \$clicked);
      
      #
      # Process events until clicked is set by button_release_event_cb.
      # We pass in may_block=TRUE since we want to wait if there
      # are no events currently.
      #
      while (!$clicked) {
	Glib::MainContext->default->iteration (TRUE);
      }
      
      $toplevel = find_toplevel_at_pointer ($screen->get_display);
      # don't move yourself
      $toplevel = undef if defined $toplevel and $toplevel == $popup;
    }
      
  $popup->destroy;
  Gtk2::Gdk->flush;			# Really release the grab
  
  return $toplevel;
}

# Prompts the user for a toplevel window to move, and then moves
# that window to the currently selected display
#
sub query_change_display {
  my $info = shift;
  my $screen = $info->{window}->get_screen;

  my $toplevel = query_for_toplevel ($screen,
				     "Please select the toplevel\n"
				     . "to move to the new screen");

  if ($toplevel) {
    $toplevel->set_screen ($info->{current_screen});
  } else {
    $screen->get_display->beep;
  }
}

#
# Fills in the screen list based on the current display
#
sub fill_screens {
  my $info = shift;

  $info->{screen_model}->clear;

  if ($info->{current_display}) {
      my $n_screens = $info->{current_display}->get_n_screens;
      
      for (my $i = 0; $i < $n_screens; $i++) {
	  my $screen = $info->{current_display}->get_screen ($i);
	  
	  my $iter = $info->{screen_model}->append;
	  $info->{screen_model}->set ($iter,
				      SCREEN_COLUMN_NUMBER, $i,
				      SCREEN_COLUMN_SCREEN, $screen);

	  $info->{screen_selection}->select_iter ($iter)
              if $i == 0;
      }
  }
}

#
# Called when the user clicks on a button in our dialog or
# closes the dialog through the window manager. Unless the
# "Change" button was clicked, we destroy the dialog.
#
sub response_cb {
  my ($dialog, $response_id, $info) = @_;

  if ($response_id eq 'ok') {
    query_change_display ($info);
  } else {
    $dialog->destroy;
  }
}

#
# Called when the user clicks on "Open..." in the display
# frame. Prompts for a new display, and then opens a connection
# to that display.
#
sub open_display_cb {
  my ($button, $info) = @_;
  my $result = undef;
  my $dialog = Gtk2::Dialog->new ("Open Display",
				  $info->{window},
				  'modal',
				  'gtk-cancel', 'cancel',
				  'gtk-ok', 'ok');

  $dialog->set_default_response ('ok');
  my $display_entry = Gtk2::Entry->new;
  $display_entry->set_activates_default (TRUE);
  my $dialog_label =
    Gtk2::Label->new ("Please enter the name of\nthe new display\n");

  $dialog->vbox->add ($dialog_label);
  $dialog->vbox->add ($display_entry);

  $display_entry->grab_focus;
  $dialog->child->show_all;
  
  while (!$result) {
      my $response_id = $dialog->run;
      last unless $response_id eq 'ok';
      
      my $new_screen_name = $display_entry->get_chars (0, -1);

      if (length $new_screen_name) {
	  $result = Gtk2::Gdk::Display->open ($new_screen_name);
	  if (!$result) {
	      $dialog_label->set_text ("Can't open display :\n\t$new_screen_name\nplease try another one\n");
	  }
      }
  }
  
  $dialog->destroy;
}

#
# Called when the user clicks on the "Close" button in the
# "Display" frame. Closes the selected display.
#
sub close_display_cb {
  my ($button, $info) = @_;
  $info->{current_display}->close
     if $info->{current_display};
}

#
# Called when the selected row in the display list changes.
# Updates info->current_display, then refills the list of
# screens.
#
sub display_changed_cb {
  my ($selection, $info) = @_;

  my ($model, $iter) = $selection->get_selected;
  if ($iter) {
    my ($d) = $model->get ($iter, DISPLAY_COLUMN_DISPLAY);
    $info->{current_display} = $d;
  } else {
    delete $info->{current_display};
  }

  fill_screens ($info);
}

#
# Called when the selected row in the sceen list changes.
# Updates info->current_screen.
#
sub screen_changed_cb {
  my ($selection, $info) = @_;

  my ($model, $iter) = $selection->get_selected;

  if ($iter) {
    my ($s) = $model->get ($iter, SCREEN_COLUMN_SCREEN);
    $info->{current_screen} = $s;
  } else {
    $info->{current_screen} = undef;
  }
}

#
# This function is used both for creating the "Display" and
# "Screen" frames, since they have a similar structure. The
# caller hooks up the right context for the value returned
# in tree_view, and packs any relevant buttons into button_vbox.
#
sub create_frame {
  my ($info, $title) = @_;
  
  my $frame = Gtk2::Frame->new ($title);

  my $hbox = Gtk2::HBox->new (FALSE, 8);
  $hbox->set_border_width (8);
  $frame->add ($hbox);

  my $scrollwin = Gtk2::ScrolledWindow->new;
  $scrollwin->set_policy ('never', 'automatic');
  $scrollwin->set_shadow_type ('in');
  $hbox->pack_start ($scrollwin, TRUE, TRUE, 0);

  my $tree_view = Gtk2::TreeView->new;
  $tree_view->set_headers_visible (FALSE);
  $scrollwin->add ($tree_view);

  my $selection = $tree_view->get_selection;
  $selection->set_mode ('browse');

  my $button_vbox = Gtk2::VBox->new (FALSE, 5);
  $hbox->pack_start ($button_vbox, FALSE, FALSE, 0);

  if (!$info->{size_group}) {
    $info->{size_group} = Gtk2::SizeGroup->new ('horizontal');
  }
  
  $info->{size_group}->add_widget ($button_vbox);

  return ($frame, $tree_view, $button_vbox);
}

#
# If we have a stack of buttons, it often looks better if their contents
# are left-aligned, rather than centered. This function creates a button
# and left-aligns it contents.
#
sub left_align_button_new {
  my $label = shift;
  my $button = Gtk2::Button->new_with_mnemonic ($label);
  $button->get_child->set_alignment (0.0, 0.5);
  return $button;
}

#
# Creates the "Display" frame in the main window.
#
sub create_display_frame {
  my $info = shift;

  my ($frame, $tree_view, $button_vbox) = create_frame ($info, "Display");

  my $button = left_align_button_new ("_Open...");
  $button->signal_connect (clicked => \&open_display_cb, $info);
  $button_vbox->pack_start ($button, FALSE, FALSE, 0);
  
  $button = left_align_button_new ("_Close");
  $button->signal_connect (clicked => \&close_display_cb, $info);
  $button_vbox->pack_start ($button, FALSE, FALSE, 0);

  $info->{display_model} =
              Gtk2::ListStore->new ("Glib::String", "Gtk2::Gdk::Display");

  $tree_view->set_model ($info->{display_model});

  my $column = Gtk2::TreeViewColumn->new_with_attributes ("Name",
						Gtk2::CellRendererText->new,
						text => DISPLAY_COLUMN_NAME);
  $tree_view->append_column ($column);

  my $selection = $tree_view->get_selection;
  $selection->signal_connect (changed => \&display_changed_cb, $info);

  return $frame;
}

#
# Creates the "Screen" frame in the main window.
#
sub create_screen_frame {
  my $info = shift;

  my ($frame, $tree_view, $button_vbox) = create_frame ($info, "Screen");

  $info->{screen_model} = Gtk2::ListStore->new ("Glib::Int", "Gtk2::Gdk::Screen");

  $tree_view->set_model ($info->{screen_model});

  my $column = Gtk2::TreeViewColumn->new_with_attributes ("Number",
					Gtk2::CellRendererText->new,
					text => SCREEN_COLUMN_NUMBER);
  $tree_view->append_column ($column);

  $info->{screen_selection} = $tree_view->get_selection;
  $info->{screen_selection}->signal_connect (changed => \&screen_changed_cb, $info);

  return $frame;
}

#
# Called when one of the currently open displays is closed.
# Remove it from our list of displays.
#
sub display_closed_cb {
  my ($display, $is_error, $info) = @_;

  my $iter = $info->{display_model}->get_iter_first;

  while ($iter) {
      my ($tmp_display) =
            $info->{display_model}->get ($iter,  DISPLAY_COLUMN_DISPLAY);

      if ($tmp_display == $display) {
	  $info->{display_model}->remove ($iter);
	  last;
      }
      $iter = $info->{display_model}->iter_next ($iter);
  }
}

#
# Adds a new display to our list of displays, and connects
# to the "closed" signal so that we can remove it from the
# list of displays again.
#
sub add_display {
  my ($info, $display) = @_;

  my $name = $display->get_name;
  
  my $iter = $info->{display_model}->append;
  $info->{display_model}->set ($iter,
                               DISPLAY_COLUMN_NAME,    $name,
                               DISPLAY_COLUMN_DISPLAY, $display);

  $display->signal_connect (closed => \&display_closed_cb, $info); 
}

#
# Called when a new display is opened
#
sub display_opened_cb {
  my ($manager, $display, $info) = @_;
  add_display ($info, $display);
}

#
# Adds all currently open displays to our list of displays,
# and set up a signal connection so that we'll be notified
# when displays are opened in the future as well.
#
sub initialize_displays {
  my $info = shift;
  my $manager = Gtk2::Gdk::DisplayManager->get;

  foreach my $display ($manager->list_displays) {
    add_display ($info, $display);
  }

  $manager->signal_connect (display_opened => \&display_opened_cb, $info);
}

#
# Cleans up when the toplevel is destroyed; we remove the
# connections we use to track currently open displays, then
# free the ChangeDisplayInfo structure.
#
sub destroy_info {
  my $info = shift;

  my $manager = Gtk2::Gdk::DisplayManager->get;
  my @displays = $manager->list_displays;

  $manager->signal_handlers_disconnect_by_func (\&display_opened_cb, $info);

  foreach my $display ($manager->list_displays) {
    $display->signal_handlers_disconnect_by_func (\&display_closed_cb, $info);
  }
  
  $info = undef;
}

sub destroy_cb {
  my ($object, $inforef) = @_;
  destroy_info ($$inforef);
  $$inforef = undef; # just to be sure
}

my $info = undef;
#
# Main entry point. If the dialog for this demo doesn't yet exist, creates
# it. Otherwise, destroys it.
#
sub do {
  if (!$info) {
    $info = {};

    if ($ver = Gtk2->check_version (2, 2, 0)) {
        my $dialog = Gtk2::MessageDialog->new (undef,
					       'destroy-with-parent',
					       'info', 'ok',
					       $ver."\n\nThis sample requires"
					       ." at least Gtk+ version 2.2.0");
	$dialog->show;
	$dialog->signal_connect (destroy => sub {$info = undef});
	$dialog->signal_connect (response => sub {$dialog->destroy; 1});
	$info->{window} = $dialog;
    } else {

      $info->{window} = Gtk2::Dialog->new ("Change Screen or display",
                                           undef, # parent
                                           'no-separator',
                                           'gtk-close' => 'close',
                                           'Change'    => 'ok');

      $info->{window}->set_default_size (300, 400);

      $info->{window}->signal_connect (response => \&response_cb, $info);
      $info->{window}->signal_connect (destroy => \&destroy_cb, \$info);

      my $vbox = Gtk2::VBox->new (FALSE, 5);
      $vbox->set_border_width (8);
	
      $info->{window}->vbox->pack_start ($vbox, TRUE, TRUE, 0);

      my $frame = create_display_frame ($info);
      $vbox->pack_start ($frame, TRUE, TRUE, 0);
      
      $frame = create_screen_frame ($info);
      $vbox->pack_start ($frame, TRUE, TRUE, 0);

      initialize_displays ($info);

      $info->{window}->show_all;
      return $info->{window};
    }
  } else {
      $info->{window}->destroy;
      return undef;
  }
}

1;
__END__
Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 
51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.
