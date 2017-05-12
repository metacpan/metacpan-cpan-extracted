# Tree View/List Store
#
# The GtkListStore is used to store data in list form, to be used
# later on by a GtkTreeView to display it. This demo builds a
# simple GtkListStore and displays it. See the Stock Browser
# demo for a more advanced example.
#
#

package list_store;

use Glib qw(TRUE FALSE);
use Gtk2;

use constant COLUMN_FIXED       => 0;
use constant COLUMN_NUMBER      => 1;
use constant COLUMN_SEVERITY    => 2;
use constant COLUMN_DESCRIPTION => 3;
use constant NUM_COLUMNS        => 4;

my @data = (
  { fixed => FALSE, number => 60482, severity => "Normal",     description => "scrollable notebooks and hidden tabs" },
  { fixed => FALSE, number => 60620, severity => "Critical",   description => "gdk_window_clear_area (gdkwindow-win32.c) is not thread-safe" },
  { fixed => FALSE, number => 50214, severity => "Major",      description => "Xft support does not clean up correctly" },
  { fixed => TRUE,  number => 52877, severity => "Major",      description => "GtkFileSelection needs a refresh method. " },
  { fixed => FALSE, number => 56070, severity => "Normal",     description => "Can't click button after setting in sensitive" },
  { fixed => TRUE,  number => 56355, severity => "Normal",     description => "GtkLabel - Not all changes propagate correctly" },
  { fixed => FALSE, number => 50055, severity => "Normal",     description => "Rework width/height computations for TreeView" },
  { fixed => FALSE, number => 58278, severity => "Normal",     description => "gtk_dialog_set_response_sensitive () doesn't work" },
  { fixed => FALSE, number => 55767, severity => "Normal",     description => "Getters for all setters" },
  { fixed => FALSE, number => 56925, severity => "Normal",     description => "Gtkcalender size" },
  { fixed => FALSE, number => 56221, severity => "Normal",     description => "Selectable label needs right-click copy menu" },
  { fixed => TRUE,  number => 50939, severity => "Normal",     description => "Add shift clicking to GtkTextView" },
  { fixed => FALSE, number => 6112,  severity => "Enhancement",description => "netscape-like collapsable toolbars" },
  { fixed => FALSE, number => 1,     severity => "Normal",     description => "First bug :=)" },
);

sub create_model {
  # create list store
  my $store = Gtk2::ListStore->new ('Glib::Boolean', # => G_TYPE_BOOLEAN
                                    'Glib::Uint',    # => G_TYPE_UINT
                                    'Glib::String',  # => G_TYPE_STRING
                                    'Glib::String'); # you get the idea

  # add data to the list store
  foreach my $d (@data) {
      my $iter = $store->append;
      $store->set ($iter,
		   COLUMN_FIXED, $d->{fixed},
		   COLUMN_NUMBER, $d->{number},
		   COLUMN_SEVERITY, $d->{severity},
		   COLUMN_DESCRIPTION, $d->{description},
      );
  }

  return $store;
}

sub fixed_toggled {
  my ($cell, $path_str, $model) = @_;
#  my $path = Gtk2::TreePath->new_from_string ($path_str);
  my $path = Gtk2::TreePath->new ($path_str);

  # get toggled iter
  my $iter = $model->get_iter ($path);
  my ($fixed) = $model->get ($iter, COLUMN_FIXED);

  # do something with the value
  $fixed ^= 1;

  # set new value
  $model->set ($iter, COLUMN_FIXED, $fixed);
}

sub add_columns {
  my $treeview = shift;

  my $model = $treeview->get_model;

  # column for fixed toggles
  my $renderer = Gtk2::CellRendererToggle->new;
  $renderer->signal_connect (toggled => \&fixed_toggled, $model);

  my $column = Gtk2::TreeViewColumn->new_with_attributes ("Fixed?",
							  $renderer,
							  active => COLUMN_FIXED);

  # set this column to a fixed sizing (of 50 pixels)
  $column->set_sizing ('fixed');
  $column->set_fixed_width (50);
  $treeview->append_column ($column);

  # column for bug numbers
  $renderer = Gtk2::CellRendererText->new;
  $column = Gtk2::TreeViewColumn->new_with_attributes ("Bug number",
						     $renderer,
						     text => COLUMN_NUMBER);
  $column->set_sort_column_id (COLUMN_NUMBER);
  $treeview->append_column ($column);

  # column for severities
  $renderer = Gtk2::CellRendererText->new;
  $column = Gtk2::TreeViewColumn->new_with_attributes ("Severity",
						       $renderer,
						       text => COLUMN_SEVERITY);
  $column->set_sort_column_id (COLUMN_SEVERITY);
  $treeview->append_column ($column);

  # column for description
  $renderer = Gtk2::CellRendererText->new;
  $column = Gtk2::TreeViewColumn->new_with_attributes ("Description",
						       $renderer,
						       text => COLUMN_DESCRIPTION);
  $column->set_sort_column_id (COLUMN_DESCRIPTION);
  $treeview->append_column ($column);
}

sub do {
  if (!$window) {

    # create window, etc
    $window = Gtk2::Window->new ('toplevel');
    $window->set_title ('GtkListStore demo');

    $window->signal_connect (destroy => sub { $window = undef });
    $window->set_border_width (8);

    my $vbox = Gtk2::VBox->new (FALSE, 8);
    $window->add ($vbox);

    my $label = Gtk2::Label->new ("This is the bug list (note: not based on real data, it would be nice to have a nice ODBC interface to bugzilla or so, though).");
    $vbox->pack_start ($label, FALSE, FALSE, 0);

    my $sw = Gtk2::ScrolledWindow->new (undef, undef);
    $sw->set_shadow_type ('etched-in');
    $sw->set_policy ('never', 'automatic');
    $vbox->pack_start ($sw, TRUE, TRUE, 0);

    # create tree model
    my $model = create_model ();

    # create tree view
    my $treeview = Gtk2::TreeView->new ($model);
    $treeview->set_rules_hint (TRUE);
    $treeview->set_search_column (COLUMN_DESCRIPTION);

    $sw->add ($treeview);

    # add columns to the tree view
    add_columns ($treeview);

    # finish & show
    $window->set_default_size (280, 250);
  }

  if (!$window->visible) {
    $window->show_all;
  } else {
    $window->destroy;
    $window = undef;
  }

  return $window;
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
