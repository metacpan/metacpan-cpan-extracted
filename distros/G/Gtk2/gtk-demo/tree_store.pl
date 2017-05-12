# Tree View/Tree Store
#
# The GtkTreeStore is used to store data in tree form, to be
# used later on by a GtkTreeView to display it. This demo builds
# a simple GtkTreeStore and displays it. If you're new to the
# GtkTreeView widgets and associates, look into the GtkListStore
# example first.
#

package tree_store;

use Gtk2;
use Glib qw(TRUE FALSE);

my $window = undef;

# columns
use constant HOLIDAY_NAME_COLUMN => 0;
use constant ALEX_COLUMN         => 1;
use constant HAVOC_COLUMN        => 2;
use constant TIM_COLUMN          => 3;
use constant OWEN_COLUMN         => 4;
use constant DAVE_COLUMN         => 5;

use constant VISIBLE_COLUMN      => 6;
use constant WORLD_COLUMN        => 7;
use constant NUM_COLUMNS         => 8;


#
# tree data 
#

my @january = (
  { label => "New Years Day",              alex => TRUE,  havoc => TRUE, tim => TRUE,  owen => TRUE, dave => FALSE, world_holiday => TRUE  },
  { label => "Presidential Inauguration",  alex => FALSE, havoc => TRUE, tim => FALSE, owen => TRUE, dave => FALSE, world_holiday => FALSE },
  { label => "Martin Luther King Jr. day", alex => FALSE, havoc => TRUE, tim => FALSE, owen => TRUE, dave => FALSE, world_holiday => FALSE },
);

my @february = (
  { label => "Presidents' Day", alex => FALSE, havoc => TRUE,  tim => FALSE, owen => TRUE,  dave => FALSE, world_holiday => FALSE },
  { label => "Groundhog Day",   alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
  { label => "Valentine's Day", alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => TRUE,  world_holiday => TRUE  },
);

my @march = (
  { label => "National Tree Planting Day", alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
  { label => "St Patrick's Day",           alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => TRUE  },
);

my @april = (
  { label => "April Fools' Day",                  alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => TRUE  },
  { label => "Army Day",                          alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
  { label => "Earth Day",                         alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => TRUE  },
  { label => "Administrative Professionals' Day", alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
);

my @may = (
  { label => "Nurses' Day",            alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
  { label => "National Day of Prayer", alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
  { label => "Mothers' Day",           alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => TRUE  },
  { label => "Armed Forces Day",       alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
  { label => "Memorial Day",           alex => TRUE,  havoc => TRUE,  tim => TRUE,  owen => TRUE,  dave => FALSE, world_holiday => TRUE  },
);

my @june = (
  { label => "June Fathers' Day",                 alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => TRUE  },
  { label => "Juneteenth (Liberation of Slaves)", alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
  { label => "Flag Day",                          alex => FALSE, havoc => TRUE,  tim => FALSE, owen => TRUE,  dave => FALSE, world_holiday => FALSE },
);

my @july = (
  { label => "Parents' Day",     alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => TRUE  },
  { label => "Independence Day", alex => FALSE, havoc => TRUE,  tim => FALSE, owen => TRUE,  dave => FALSE, world_holiday => FALSE },
);

my @august = (
  { label => "Air Force Day",   alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
  { label => "Coast Guard Day", alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
  { label => "Friendship Day",  alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
);

my @september = (
  { label => "Grandparents' Day",                   alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => TRUE  },
  { label => "Citizenship Day or Constitution Day", alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
  { label => "Labor Day",                           alex => TRUE,  havoc => TRUE,  tim => TRUE,  owen => TRUE,  dave => FALSE, world_holiday => TRUE  },
);

my @october = (
  { label => "National Children's Day", alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
  { label => "Bosses' Day",             alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
  { label => "Sweetest Day",            alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
  { label => "Mother-in-Law's Day",     alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
  { label => "Navy Day",                alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
  { label => "Columbus Day",            alex => FALSE, havoc => TRUE,  tim => FALSE, owen => TRUE,  dave => FALSE, world_holiday => FALSE },
  { label => "Halloween",               alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => TRUE  },
);

my @november = (
  { label => "Marine Corps Day", alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
  { label => "Veterans' Day",    alex => TRUE,  havoc => TRUE,  tim => TRUE,  owen => TRUE,  dave => FALSE, world_holiday => TRUE  },
  { label => "Thanksgiving",     alex => FALSE, havoc => TRUE,  tim => FALSE, owen => TRUE,  dave => FALSE, world_holiday => FALSE },
);

my @december = (
  { label => "Pearl Harbor Remembrance Day", alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
  { label => "Christmas",                    alex => TRUE,  havoc => TRUE,  tim => TRUE,  owen => TRUE,  dave => FALSE, world_holiday => TRUE  },
  { label => "Kwanzaa",                      alex => FALSE, havoc => FALSE, tim => FALSE, owen => FALSE, dave => FALSE, world_holiday => FALSE },
);


my @toplevel = (
  {label => "January",     children => \@january},
  {label => "February",    children => \@february},
  {label => "March",       children => \@march},
  {label => "April",       children => \@april},
  {label => "May",         children => \@may},
  {label => "June",        children => \@june},
  {label => "July",        children => \@july},
  {label => "August",      children => \@august},
  {label => "September",   children => \@september},
  {label => "October",     children => \@october},
  {label => "November",    children => \@november},
  {label => "December",    children => \@december},
);


#static GtkTreeModel *
#create_model (void)
sub create_model {
   # create tree store
#  model = gtk_tree_store_new (NUM_COLUMNS,
#			      G_TYPE_STRING,
#			      G_TYPE_BOOLEAN,
#			      G_TYPE_BOOLEAN,
#			      G_TYPE_BOOLEAN,
#			      G_TYPE_BOOLEAN,
#			      G_TYPE_BOOLEAN,
#			      G_TYPE_BOOLEAN,
#			      G_TYPE_BOOLEAN);
   my $model = Gtk2::TreeStore->new (qw/ Glib::String 
                                         Glib::Boolean 
                                         Glib::Boolean 
                                         Glib::Boolean 
                                         Glib::Boolean 
                                         Glib::Boolean 
                                         Glib::Boolean 
                                         Glib::Boolean /);

   # add data to the tree store/
   foreach my $month (@toplevel) {
       my $iter = $model->append (undef);
       $model->set ($iter,
                    HOLIDAY_NAME_COLUMN, $month->{label},
                    ALEX_COLUMN,    FALSE,
                    HAVOC_COLUMN,   FALSE,
                    TIM_COLUMN,     FALSE,
                    OWEN_COLUMN,    FALSE,
                    DAVE_COLUMN,    FALSE,
                    VISIBLE_COLUMN, FALSE,
                    WORLD_COLUMN,   FALSE);

       # add children
       foreach my $holiday (@{ $month->{children} }) {
          my $child_iter = $model->append ($iter);
          $model->set ($child_iter,
                       HOLIDAY_NAME_COLUMN, $holiday->{label},
                       ALEX_COLUMN, $holiday->{alex},
                       HAVOC_COLUMN, $holiday->{havoc},
                       TIM_COLUMN, $holiday->{tim},
                       OWEN_COLUMN, $holiday->{owen},
                       DAVE_COLUMN, $holiday->{dave},
                       VISIBLE_COLUMN, TRUE,
                       WORLD_COLUMN, $holiday->{world_holiday});
       }
    }

    return $model;
}

#static void
#item_toggled (GtkCellRendererToggle *cell,
#	      gchar                 *path_str,
#	      gpointer               data)
sub item_toggled {
   my ($cell, $path_str, $model) = @_;
   my $path = Gtk2::TreePath->new_from_string ($path_str);

   my $column = $cell->get_data ("column");
   warn ("column is $column\n");

   # get toggled iter
   $iter = $model->get_iter ($path);
   my ($toggle_item) = $model->get ($iter, $column);

   # do something with the value
   $toggle_item ^= 1;

   # set new value
   $model->set ($iter, $column, $toggle_item);

#  /* clean up */
#  gtk_tree_path_free (path);
}

#static void
#add_columns (GtkTreeView *treeview)
sub add_columns {
   my $treeview = shift;
   my $model = $treeview->get_model;

   # column for holiday names
   my $renderer = Gtk2::CellRendererText->new;
   $renderer->set (xalign => 0.0);

   my $col_offset = $treeview->insert_column_with_attributes 
   					(-1, "Holiday", $renderer,
					 text => HOLIDAY_NAME_COLUMN);
   my $column = $treeview->get_column ($col_offset - 1);
   $column->set_clickable (TRUE);

   # alex column
   $renderer = Gtk2::CellRendererToggle->new;
   $renderer->set (xalign => 0.0);
   $renderer->set_data (column => ALEX_COLUMN);

   $renderer->signal_connect (toggled => \&item_toggled, $model);

   $col_offset = $treeview->insert_column_with_attributes 
 					(-1, "Alex", $renderer,
					 active => ALEX_COLUMN, 
					 visible => VISIBLE_COLUMN,
					 activatable => WORLD_COLUMN);

   $column = $treeview->get_column ($col_offset - 1);
   $column->set_sizing ('fixed');
   $column->set_fixed_width (50);
   $column->set_clickable (TRUE);

   # havoc column
   $renderer = Gtk2::CellRendererToggle->new;
   $renderer->set (xalign => 0.0);
   $renderer->set_data (column => HAVOC_COLUMN);

   $renderer->signal_connect (toggled => \&item_toggled, $model);

   $col_offset = $treeview->insert_column_with_attributes 
   					(-1, "Havoc", $renderer,
					 active => HAVOC_COLUMN, 
					 visible => VISIBLE_COLUMN);

   $column = $treeview->get_column ($col_offset - 1);
   $column->set_sizing ('fixed');
   $column->set_fixed_width (50);
   $column->set_clickable (TRUE);

   # tim column
   $renderer = Gtk2::CellRendererToggle->new;
   $renderer->set (xalign => 0.0);
   $renderer->set_data (column => TIM_COLUMN);

   $renderer->signal_connect (toggled => \&item_toggled, $model);

   $col_offset = $treeview->insert_column_with_attributes 
					(-1, "Tim", $renderer,
					 active => TIM_COLUMN,
					 visible => VISIBLE_COLUMN,
					 activatable => WORLD_COLUMN);

   $column = $treeview->get_column ($col_offset - 1);
   $column->set_sizing ('fixed');
   $column->set_fixed_width (50);
   $column->set_clickable (TRUE);

   # owen column
   $renderer = Gtk2::CellRendererToggle->new;
   $renderer->set (xalign => 0.0);
   $renderer->set_data (column => OWEN_COLUMN);

   $renderer->signal_connect (toggled => \&item_toggled, $model);

   $col_offset = $treeview->insert_column_with_attributes 
   					(-1, "Owen", $renderer,
					 active => OWEN_COLUMN,
					 visible => VISIBLE_COLUMN);

   $column = $treeview->get_column ($col_offset - 1);
   $column->set_sizing ('fixed');
   $column->set_fixed_width (50);
   $column->set_clickable (TRUE);

   # dave column
   $renderer = Gtk2::CellRendererToggle->new;
   $renderer->set (xalign => 0.0);
   $renderer->set_data (column => DAVE_COLUMN);

   $renderer->signal_connect (toggled => \&item_toggled, $model);

   $col_offset = $treeview->insert_column_with_attributes 
   				   (-1, "Dave", $renderer,
				    active => DAVE_COLUMN,
				    visible => VISIBLE_COLUMN);

   $column = $treeview->get_column ($col_offset - 1);
   $column->set_sizing ('fixed');
   $column->set_fixed_width (50);
   $column->set_clickable (TRUE);
}

sub do {
  if (!$window) {
       # create window, etc
       $window = Gtk2::Window->new ('toplevel');
       $window->set_title ("Card planning sheet");
       $window->signal_connect (destroy => sub { $window = undef });

       my $vbox = Gtk2::VBox->new (FALSE, 8);
       $vbox->set_border_width (8);
       $window->add ($vbox);

       $vbox->pack_start (Gtk2::Label->new ("Jonathan's Holiday Card Planning Sheet"),
 			  FALSE, FALSE, 0);

       my $sw = Gtk2::ScrolledWindow->new (undef, undef);
       $sw->set_shadow_type ('etched-in');
       $sw->set_policy ('automatic', 'automatic');
       $vbox->pack_start ($sw, TRUE, TRUE, 0);

       # create model
       my $model = create_model ();

       # create tree view
       ##my $treeview = Gtk2::TreeView->new_with_model ($model);
       my $treeview = Gtk2::TreeView->new ($model);
###      g_object_unref (model);
       $treeview->set_rules_hint (TRUE);
       $treeview->get_selection->set_mode ('multiple');

       add_columns ($treeview);

       $sw->add ($treeview);

       # expand all rows after the treeview widget has been realized
       $treeview->signal_connect (realize => sub { $_[0]->expand_all; 1 });
       $window->set_default_size (650, 400);
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
