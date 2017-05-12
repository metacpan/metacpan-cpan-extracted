#!/usr/bin/perl -w
#
# Stock Item and Icon Browser
#
# This source code for this demo doesn't demonstrate anything
# particularly useful in applications. The purpose of the "demo" is
# just to provide a handy place to browse the available stock icons
# and stock items.
#

package stock_browser;

use Glib qw(TRUE FALSE);
use Gtk2;

my $window = undef;

#
# The C version of this sample defines a structure called StockItemInfo
# to hold information about the stock items; it makes StockItemInfo into
# a new boxed type so that, when used with the GtkListStore, all the 
# memory management happens properly.
#
# in perl we don't do such things.  the StockItemInfo structure becomes
# just a perl hash, and we store it in the Gtk2::ListStore in a column
# with the Glib::Scalar type.  this way all the memory management happens
# properly and you don't have to think up elaborate schemes to do so
# (because i already did it for you).
#


sub id_to_macro {
   my $id = shift;
   my $macro = uc($id);
   $macro =~ s/-/_/g;
   $macro =~ s/^GTK_/GTK_STOCK_/;
   return $macro;
}

sub create_model {
  #store = gtk_list_store_new (2, STOCK_ITEM_INFO_TYPE, G_TYPE_STRING);
  #my $store = Gtk2::ListStore->new ('scalar', 'Glib::String');
  my $store = Gtk2::ListStore->new ('Glib::Scalar', 'Glib::String');

   foreach my $id (sort Gtk2::Stock->list_ids) {
       my $item = Gtk2::Stock->lookup ($id);

       my %info = (
               id   => $id,
               item => $item ? $item : {}
       );

       # only show icons for stock IDs that have default icons
       my $icon_set = Gtk2::IconFactory->lookup_default ($info{id});
       if ($icon_set) {
           # See at which sizes this stock icon really exists
           my @sizes = $icon_set->get_sizes;
 
           # Use menu size if it exists, otherwise first size found
           my $size = grep (@sizes, 'menu')
                    ? 'menu'
                    : $sizes[0];
          
           $info{small_icon} = $window->render_icon ($info{id}, $size);
          
           if ($size ne 'menu') {
               # Make the result the proper size for our thumbnail
               $info{small_icon} = 
                         Gtk2::Gdk::Pixbuf->scale_simple ($info{small_icon},
                                         Gtk2::Icon->size_lookup ('menu'),
                                         'bilinear');
           }
       }

       $info{accel_str} = $info{item}{keyval}
                        ? Gtk2::Accelerator->name ($info{item}{keyval},
	                                           $info{item}{modifier})
                        : '';

       $info{macro} = id_to_macro ($info{id});

       # something about redhat9's gnome setup registers a whole slew of 
       # stock items which don't return icons in this context.  i don't
       # know if it's because we don't do Gnome2::Program->init or what,
       # but it's really annoying, because it messes with lots of things,
       # and since you can't pass undef/null for an object property, we
       # can't tell the cell renderers to use NULL for the pixbufs.
       # so, we only add an entry for stock items which have icons.
       if ($info{small_icon}) { 
         my $iter = $store->append;
         $store->set ($iter, 0, \%info, 1, $id);
       }
  }
  return $store;
}

#
# Finds the largest size at which the given image stock id is
# available. This would not be useful for a normal application
#
sub get_largest_size {
  my $id = shift;
  my $best_size = 'invalid';
  my $best_pixels = 0;

  my $set = Gtk2::IconFactory->lookup_default ($id);

  foreach my $size ($set->get_sizes) {
     my ($width, $height) = Gtk2::IconSize->lookup ($size);
     next unless defined $height;
     if ($width * $height > $best_pixels) {
        $best_size = $size;
	$best_pixels = $width * $height;
     }
  }

  return $best_size;
}

sub selection_changed {
  my $selection = shift;

#  warn "\n\nselection_changed  $selection";
  
  my $treeview = $selection->get_tree_view;
  my $display = $treeview->{stock_display};

  my ($model, $iter) = $selection->get_selected;
  if ($iter) {
      my ($info) = $model->get ($iter, 0);

      if ($info->{small_icon} && $info->{item}{label}) {
        $display->{type_label}->set_text ("Icon and Item");
      } elsif ($info->{small_icon}) {
        $display->{type_label}->set_text ("Icon Only");
      } elsif ($info->{item}{label}) {
        $display->{type_label}->set_text ("Item Only");
      } else {
        $display->{type_label}->set_text ("???????");
      }

      $display->{macro_label}->set_text ($info->{macro});
      $display->{id_label}->set_text ($info->{id});

      if ($info->{item}{label}) {
          $display->{label_accel_label}->set_text_with_mnemonic (sprintf '%s %s', $info->{item}{label}, $info->{accel_str});
      } else {
          $display->{label_accel_label}->set_text ("");
      }

      if ($info->{small_icon}) {
        $display->{icon_image}->set_from_stock ($info->{id},
                                  get_largest_size ($info->{id}));
      } else {
        $display->{icon_image}->set_from_pixbuf (undef);
      }

  } else {
      $display->{type_label}->set_text ("No selected item");
      $display->{macro_label}->set_text ("");
      $display->{id_label}->set_text ("");
      $display->{label_accel_label}->set_text ("");
      $display->{icon_image}->set_from_pixbuf (undef);
  }
}

sub macro_set_func_text {
  my ($tree_column, $cell, $model, $iter) = @_;
  
  my ($info) = $model->get ($iter, 0);
  
  $cell->set (text => $info->{macro});
}

sub macro_set_func_pixbuf {
  my ($tree_column, $cell, $model, $iter) = @_;
  my ($info) = $model->get ($iter, 0);
  $cell->set (pixbuf => $info->{small_icon});
}

sub id_set_func {
  my ($tree_column, $cell, $model, $iter) = @_;
  
  my ($info) = $model->get ($iter, 0);
  
  $cell->set (text => $info->{id});
}

sub accel_set_func {
  my ($tree_column, $cell, $model, $iter) = @_;
  my ($info) = $model->get ($iter, 0);
  $cell->set (text => $info->{accel_str});
}

sub label_set_func {
  my ($tree_column, $cell, $model, $iter) = @_;
  my ($info) = $model->get ($iter, 0);
  # items aren't required to have labels
  $cell->set (text => $info->{item}{label} || '');
}


sub do {
  if (!$window) {
      $window = Gtk2::Window->new;
      $window->set_title ("Stock Icons and Items");
      $window->set_default_size (-1, 500);

      $window->signal_connect (destroy => sub {$window = undef; 1});
      $window->set_border_width (8);

      my $hbox = Gtk2::HBox->new (FALSE, 8);
      $window->add ($hbox);

      my $sw = Gtk2::ScrolledWindow->new;
      $sw->set_policy ('never', 'automatic');
      $hbox->pack_start ($sw, FALSE, FALSE, 0);

      my $model = create_model ();
      
      my $treeview = Gtk2::TreeView->new_with_model ($model);

      $sw->add ($treeview);
      
      my $column = Gtk2::TreeViewColumn->new;
      $column->set_title ("Macro");

      my $cell_renderer = Gtk2::CellRendererPixbuf->new;
      $column->pack_start ($cell_renderer, FALSE);
### this doesn't work for 2.0.x, because stock_id isn't an attribute for the
### renderer until 2.2.x
###      $column->set_attributes ($cell_renderer, stock_id => 1);
      $column->set_cell_data_func ($cell_renderer, \&macro_set_func_pixbuf);
      $cell_renderer = Gtk2::CellRendererText->new;
      $column->pack_start ($cell_renderer, TRUE);
      $column->set_cell_data_func ($cell_renderer, \&macro_set_func_text);

      $treeview->append_column ($column);

      $cell_renderer = Gtk2::CellRendererText->new;

      $treeview->insert_column_with_data_func (-1,
                                               "Label",
                                               $cell_renderer,
                                               \&label_set_func);

      $cell_renderer = Gtk2::CellRendererText->new;
      $treeview->insert_column_with_data_func (-1,
                                               "Accel",
                                               $cell_renderer,
                                               \&accel_set_func);

      $cell_renderer = Gtk2::CellRendererText->new;
      $treeview->insert_column_with_data_func (-1,
                                               "ID",
                                               $cell_renderer,
                                               \&id_set_func);
      
      my $align = Gtk2::Alignment->new (0.5, 0.0, 0.0, 0.0);
      $hbox->pack_end ($align, FALSE, FALSE, 0);
      
      my $frame = Gtk2::Frame->new ("Selected Item");
      $align->add ($frame);

      my $vbox = Gtk2::VBox->new (FALSE, 8);
      $vbox->set_border_width (4);
      $frame->add ($vbox);

      my $display = {
         type_label => Gtk2::Label->new,
         macro_label => Gtk2::Label->new,
         id_label => Gtk2::Label->new,
         label_accel_label => Gtk2::Label->new,
         icon_image => Gtk2::Image->new_from_pixbuf (undef), # empty image
      };
      $treeview->{stock_display} = $display;

      $vbox->pack_start ($display->{type_label}, FALSE, FALSE, 0); 
      $vbox->pack_start ($display->{icon_image}, FALSE, FALSE, 0); 
      $vbox->pack_start ($display->{label_accel_label}, FALSE, FALSE, 0);
      $vbox->pack_start ($display->{macro_label}, FALSE, FALSE, 0);
      $vbox->pack_start ($display->{id_label}, FALSE, FALSE, 0);

      my $selection = $treeview->get_selection;
      $selection->set_mode ('single');
      
      $selection->signal_connect (changed => \&selection_changed);
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
