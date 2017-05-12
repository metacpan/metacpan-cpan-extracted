#!/usr/bin/perl -w
#
# Entry Completion
#
# GtkEntryCompletion provides a mechanism for adding support for
# completion in GtkEntry.
#
#

package entry_completion;

use strict;
use Glib qw(TRUE FALSE);
use Gtk2;

my $window = undef;

# Creates a tree model containing the completions
sub create_completion_model {
  my $store = Gtk2::ListStore->new (Glib::String::);

  # Append one word
  $store->set ($store->append, 0, "GNOME");

  # Append another word
  $store->set ($store->append, 0, "total");

  # And another word
  $store->set ($store->append, 0, "totally");
  
  return $store;
}


sub do {
  my $do_widget = shift;

  if (!$window) {
    $window = Gtk2::Dialog->new ("GtkEntryCompletion",
				 $do_widget,
				 [],
				 "gtk-close" => 'none');
    $window->set_resizable (FALSE);

    $window->signal_connect (response => sub {$window->destroy});
    $window->signal_connect (destroy => sub {$window = undef});

    my $vbox = Gtk2::VBox->new (FALSE, 5);
    $window->vbox->pack_start ($vbox, TRUE, TRUE, 0);
    $vbox->set_border_width (5);

    my $label = Gtk2::Label->new;
    $label->set_markup ("Completion demo, try writing <b>total</b> or <b>gnome</b> for example.");
    $vbox->pack_start ($label, FALSE, FALSE, 0);

    # Create our entry
    my $entry = Gtk2::Entry->new;
    $vbox->pack_start ($entry, FALSE, FALSE, 0);

    # Create the completion object
    my $completion = Gtk2::EntryCompletion->new;

    # Assign the completion to the entry
    $entry->set_completion ($completion);
    
    # Create a tree model and use it as the completion model
    $completion->set_model (create_completion_model ());
    
    # Use model column 0 as the text column
    $completion->set_text_column (0);
  }

  if (!$window->visible) {
    $window->show_all;
  } else {
    $window->destroy;
  }

  return $window;
}


1;
