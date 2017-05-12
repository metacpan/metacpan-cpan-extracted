# Tree View/Editable Cells
#
# This demo demonstrates the use of editable cells in a GtkTreeView. If
# you're new to the GtkTreeView widgets and associates, look into
# the GtkListStore example first.
#
#

package editable_cells;

use Glib qw(TRUE FALSE);
use Gtk2;

my $window = undef;

#typedef struct
#{
#  gint     number;
#  gchar   *product;
#  gboolean editable;
#}
#Item;

use constant COLUMN_NUMBER   => 0;
use constant COLUMN_PRODUCT  => 1;
use constant COLUMN_EDITABLE => 2;
use constant NUM_COLUMNS     => 3;

my @articles = ();

sub add_items {
  push @articles,
    { number => 3, product => "bottles of coke", editable => TRUE, },
    { number => 5, product => "packages of noodles", editable => TRUE, },
    { number => 2, product => "packages of chocolate chip cookies", editable => TRUE, },
    { number => 1, product => "can vanilla ice cream", editable => TRUE, },
    { number => 6, product => "eggs", editable => TRUE, },
  ;
}

sub create_model {
  # create array
  add_items ();

  # create list store
  my $model = Gtk2::ListStore->new (qw/Glib::Int Glib::String Glib::Boolean/);

  # add items
  foreach my $a (@articles) {
      my $iter = $model->append;

      $model->set ($iter,
                   COLUMN_NUMBER, $a->{number},
                   COLUMN_PRODUCT, $a->{product},
                   COLUMN_EDITABLE, $a->{editable});
  }

  return $model;
}

sub add_item {
  my ($button, $model) = @_;

  push @articles, {
	number => 0,
	product => "Description here",
	editable => TRUE,
  };

  my $iter = $model->append;
  $model->set ($iter,
               COLUMN_NUMBER, $articles[-1]{number},
               COLUMN_PRODUCT, $articles[-1]{product},
               COLUMN_EDITABLE, $articles[-1]{editable});
}

sub remove_item {
  my ($widget, $treeview) = @_;
  my $model = $treeview->get_model;
  my $selection = $treeview->get_selection;

  my $iter = $selection->get_selected;
  if ($iter) {
      my $path = $model->get_path ($iter);
      my $i = ($path->get_indices)[0];
      $model->remove ($iter);

      splice @articles, $i;
  }
}

sub cell_edited {
  my ($cell, $path_string, $new_text, $model) = @_;
  my $path = Gtk2::TreePath->new_from_string ($path_string);

  my $column = $cell->get_data ("column");

  my $iter = $model->get_iter ($path);

  if ($column == COLUMN_NUMBER) {
	my $i = ($path->get_indices)[0];
	$articles[$i]{number} = $new_text;

	$model->set ($iter, $column, $articles[$i]{number});

  } elsif ($column == COLUMN_PRODUCT) {
	my $i = ($path->get_indices)[0];
	$articles[$i]{product} = $new_text;

	$model->set ($iter, $column, $articles[$i]{product});
  }
}

sub add_columns {
  my $treeview = shift;
  my $model = $treeview->get_model;

  # number column
  my $renderer = Gtk2::CellRendererText->new;
  $renderer->signal_connect (edited => \&cell_edited, $model);
  $renderer->set_data (column => COLUMN_NUMBER);

  $treeview->insert_column_with_attributes (-1, "Number", $renderer,
					    text => COLUMN_NUMBER,
					    editable => COLUMN_EDITABLE);

  # product column
  $renderer = Gtk2::CellRendererText->new;
  $renderer->signal_connect (edited => \&cell_edited, $model);
  $renderer->set_data (column => COLUMN_PRODUCT);

  $treeview->insert_column_with_attributes (-1, "Product", $renderer,
					    text => COLUMN_PRODUCT,
					    editable => COLUMN_EDITABLE);
}

sub do {
  if (!$window) {
      # create window, etc
      $window = Gtk2::Window->new;
      $window->set_title ("Shopping list");
      $window->set_border_width (5);
      $window->signal_connect (destroy => sub { $window = undef; 1 });

      my $vbox = Gtk2::VBox->new (FALSE, 5);
      $window->add ($vbox);

      $vbox->pack_start (Gtk2::Label->new ("Shopping list (you can edit the cells!)"),
			 FALSE, FALSE, 0);

      my $sw = Gtk2::ScrolledWindow->new;
      $sw->set_shadow_type ('etched-in');
      $sw->set_policy ('automatic', 'automatic');
      $vbox->pack_start ($sw, TRUE, TRUE, 0);

      # create model
      my $model = create_model ();

      # create tree view
      my $treeview = Gtk2::TreeView->new_with_model ($model);
##      g_object_unref (model);
      $treeview->set_rules_hint (TRUE);
      $treeview->get_selection->set_mode ('single');

      add_columns ($treeview);

      $sw->add ($treeview);

      # some buttons
      my $hbox = Gtk2::HBox->new (TRUE, 4);
      $vbox->pack_start ($hbox, FALSE, FALSE, 0);

      my $button = Gtk2::Button->new ("Add item");
      $button->signal_connect (clicked => \&add_item, $model);
      $hbox->pack_start ($button, TRUE, TRUE, 0);

      $button = Gtk2::Button->new ("Remove item");
      $button->signal_connect (clicked => \&remove_item, $treeview);
      $hbox->pack_start ($button, TRUE, TRUE, 0);

      $window->set_default_size (320, 200);
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
