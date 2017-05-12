package Gtk2::Ex::TreeMaker;

our $VERSION = '0.11';

use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2::Ex::TreeMaker::FlatInterface;
use Data::Dumper;

=head1 NAME

Gtk2::Ex::TreeMaker - A high level widget to represent a set of relational records in a hierarchical spreadsheet kinda display. This task is typical to most of the business application user interfaces.

=head1 DESCRIPTION

Typically in business applications, users like to view data in a spreadsheet kind of display. (Columns represent timeline(typically) and rows represent measures like sales/inventory/blah/blah).

The data itself is typically stored internally as relational records. For example, here is some sales info (stored internally in a relational database)

	-------------------------------------
	Region, City, Product, Date, Quantity
	-------------------------------------
	Texas, Dallas, Fruits, Dec-2003, 300
	Texas, Dallas, Veggies, Jan-2004, 120
	Texas, Austin, Fruits, Nov-2003, 310
	Texas, Austin, Veggies, Feb-2004, 20
	-------------------------------------

The user will typically want to view the same data in a hierarchical(/spreadsheet) kinda display.

	------------------------------------------------------
	Prod / Date   Nov-2003  Dec-2003  Jan-2004  Feb-2004 
	------------------------------------------------------
	Texas
	  Dallas
		Fruits                  300             
		Veggies                           120 
	  Austin
		Fruits        310
		Veggies                                     20
	------------------------------------------------------

With web-based business apps, similar views are created in the browser using lots of html/jsp coding.

The Gtk2::TreeView is an excellent widget to display a similar presentation of data in a desktop app. But creating a (hierarchical) TreeView from flat relational data can require some recursive function coding. It would be great if all this recursive code could be abstracted out and packaged separately.

This high level widget is designed with that purpose in mind. This module will accept a relational feed of records and automatically convert it into a hierarchical treeview using the Gtk2::TreeView. The process involves invoking some recursive functions to build a TreeModel and populate it. Also, since the spreadsheet itself can be rather long horizontally, the widget also has a I<FreezePane> capability.

Details on the widget including a screenshot can be found at: http://ofey.blogspot.com/2005/02/gtk2extreemaker.html

=head1 SYNOPSIS

	use Gtk2 -init;
	use Gtk2::Ex::TreeMaker;

	# Create an array to contain the column_names. These names appear as the header for each column.
	# The first entry should be the title of the left side of the FreezePane.
	my $column_names = [
		'Name',
		'Nov-2003', 'Dec-2003', 'Jan-2004', 'Feb-2004'
	];

	# This api will have to be cleaned soon...
	# All the attributes of the cell in the treeview are specified here
	# The value for these attributes are to be populated from the recordset
	# The assumption is that the attributes are contained in the data record
	# in the same order towards the **end** of the record. (the last few fields)
	# Since we are using CellRendererText in the TreeView, any of the properties
	# of the CellRendererText can be passed using this mechanism
	# In addition to the properties of the CellRendererText, I have also added a
	# custom property called 'hyperlinked'.
	my $data_attributes = [
		{'text' => 'Glib::String'},
		{'editable' => 'Glib::Boolean'},
		{'hyperlinked' => 'Glib::Boolean'}, 
		{'background' => 'Glib::String'}, 
	];

	# Here is the set of relational records to be displayed
	my $recordset = [
		['Texas','Dallas','Fruits','Dec-2003','300',0,1,'red'],
		['Texas','Dallas','Veggies','Jan-2004','120',1,0,'blue'],
		['Texas','Austin','Fruits','Nov-2003','310',1,1,'white'],
		['Texas','Austin','Veggies','Feb-2004','20',0,1,'green']
	];

	# Initialize our new widget
	# The constructor requires two attributes
	# This constitutes of the $column_name and the $data_attributes as described above
	my $treemaker = Gtk2::Ex::TreeMaker->new($column_names, $data_attributes);

	# We will inject our relational recordset into the new widget
	$treemaker->set_data_flat(\@recordset);

	# Build the model
	$treemaker->build_model;

	# Create a root window to display the widget
	my $window = Gtk2::Window->new;
	$window->signal_connect(destroy => sub { Gtk2->main_quit; });

	# Add the widget to the root window
	$window->add($treemaker->get_widget());

	$window->set_default_size(500, 300);
	$window->show_all;
	Gtk2->main;

=head1 METHODS

=head2 Gtk2::Ex::TreeMaker->new($column_names, $data_attributes)

This is the constructor. Accepts two arguments.

First argument is the column_names list. Each element of the array is a hash. The hash uses 'ColumnName' as the key. For example,

	my $column_names = [
		'Name',
		'Nov-2003', 'Dec-2003', 'Jan-2004', 'Feb-2004'
	];

Second argument is the data_attributes list. Here you specify what attributes each record has. For example,

	my $data_attributes = [
		{'text' => 'Glib::String'},
		{'editable' => 'Glib::Boolean'},
		{'hyperlinked' => 'Glib::Boolean'}, 
		{'background' => 'Glib::String'}, 
	];

All the attributes of the cell in the treeview are specified here. The value for these attributes are to be populated from the recordset. 
The assumption is that the attributes are contained in the data record
in the same order towards the B<**end**> of the record. (the last few fields)

Since we are using C<Gtk2::CellRendererText> in the TreeView, any of the properties
of the C<Gtk2::CellRendererText> can be passed using this mechanism
In addition to the properties of the CellRendererText, I have also added a
custom property called 'hyperlinked'.

=cut

sub new {
	my ($class, $column_names, $data_attributes) = @_;
	my $self  = {};
	$self->{data_tree} = undef;
	$self->{data_attributes} = undef;
	$self->{edited_data_flat} = [];
	$self->{data_tree_depth} = undef;
	$self->{column_names} = undef;
	$self->{treeview_columns} = undef;
	$self->{frozen_column} = undef;
	$self->{tree_store_full} = undef;
	$self->{tree_store_frozen} = undef;
	$self->{tree_view_full} = undef;
	$self->{tree_view_frozen} = undef;
	$self->{chosen_column} = undef;
	$self->{signals} = undef;
	bless ($self, $class);
	$self->set_meta_data($column_names, $data_attributes);
	return $self;
}

=head2 Gtk2::Ex::TreeMaker->set_data_flat($data_flat)

This sub is used to inject the relational recordset into the widget. This sub accepts a set of relational records (an array of arrays) as the argument. For example,

	my $recordset = [
		['Texas','Dallas','Fruits','Dec-2003','300',0,1,'red'],
		['Texas','Dallas','Veggies','Jan-2004','120',1,0,'blue'],
		['Texas','Austin','Fruits','Nov-2003','310',1,1,'white'],
		['Texas','Austin','Veggies','Feb-2004','20',0,1,'green']
	];

=cut

sub set_data_flat {
	my ($self, $data_flat) = @_;
	my $flat_interface = Gtk2::Ex::TreeMaker::FlatInterface->new();
	my $data_tree = $flat_interface->flat_to_tree($self->{data_attributes}, $data_flat);
	$self->{data_tree} = $data_tree;
}

# This method is temporarily not required. Will come back to it later
# Leave it in there for now
sub set_data_tree_depth {
	my ($self, $data_tree_depth) = @_;
	$self->{data_tree_depth} = $data_tree_depth;
}

=head2 Gtk2::Ex::TreeMaker->signal_connect($signal_name, $action)

Currently, four signals are suppoted

=over 4

=item * cell-edited

Thrown only for 'editable' cells.

=item * cell-clicked

Thrown only for 'hyperlinked' cells.

=item * cell-enter

Thrown only for 'hyperlinked' cells.

=item * cell-leave

Thrown only for 'hyperlinked' cells.

=back

=cut

sub signal_connect {
	my ($self, $signal, $action) = @_;
	$self->{signals}->{$signal} = $action;
}

sub set_meta_data {
	my ($self, $col_names, $data_attributes) = @_;
	$self->{data_attributes} = $data_attributes;
	my $column_names = [];
	foreach my $col_name(@$col_names) {
		push @$column_names, { ColumnName => $col_name};
	}
	# Add an emtpy column in the end for display purposes
	push @$column_names, { ColumnName => ''};
	$self->{column_names} = $column_names;
	$self->{frozen_column} = [$column_names->[0]];
	my @temp;
	my @column_attr;
	my $count=0;
	foreach my $attr (@$data_attributes) {
		foreach my $key (keys %$attr) {
			push @temp, $attr->{$key};

			# Here is the logic for dealing with the 'custom' properties
			# All the properties that don't belong to the CellRendererText has to be handled here
			# Else, the CellRendererText is gonna complain.
			if ($key eq 'hyperlinked') {
				$key = 'underline';
			}

			push @column_attr, $key;
			push @column_attr, $count++;
		}
	}   

	my @tree_store_full_types = map {@temp} @{$self->{column_names}};
	my @tree_store_frozen_types = map {@temp} @{$self->{frozen_column}};
	my $tree_store_full = Gtk2::TreeStore->new(@tree_store_full_types);
	my $tree_store_frozen = Gtk2::TreeStore->new(@tree_store_frozen_types);
	$self->{tree_store_full} = $tree_store_full;
	$self->{tree_store_frozen} = $tree_store_frozen;
	my $tree_view_full = Gtk2::TreeView->new($tree_store_full);
	my $tree_view_frozen = Gtk2::TreeView->new($tree_store_frozen);

	$tree_view_full->set_rules_hint(TRUE);
	$tree_view_frozen->set_rules_hint(TRUE);

	#$tree_view_full->get_selection->set_mode ('none');
	#$tree_view_frozen->get_selection->set_mode ('none');

	_synchronize_trees($tree_view_frozen, $tree_view_full);
	$self->{tree_view_full} = $tree_view_full;
	$self->{tree_view_frozen} = $tree_view_frozen;

	$self->_create_columns ($self->{column_names}, $tree_store_full, $tree_view_full);
	# There is only one column (the first column) in this case
	my $column_name =  $self->{frozen_column}->[0]->{ColumnName};  
	my $column = Gtk2::TreeViewColumn->new_with_attributes(
		$column_name, Gtk2::CellRendererText->new(), @column_attr);
	$column->set_resizable(TRUE);
	$tree_view_frozen->append_column($column);   
		
	my $treemaker_self = $self;

	# If the cell is hyperlinked, then change the mouse pointer to something else
	# This will give a visual feedback to the user that he should click on the cell
	$tree_view_full->signal_connect('motion-notify-event' =>
		sub {        
			my ($self, $event) = @_;
			my ($path, $column, $cell_x, $cell_y) = $self->get_path_at_pos ($event->x, $event->y);
			my $cursor = undef;
			if ($path) {
				my $model = $self->get_model;
				my $hyperlinked;
				if (defined $column->{hyperlinked}){
					$hyperlinked = $model->get ($model->get_iter ($path), $column->{hyperlinked});
				}
				if ($hyperlinked) {
					$self->{cursor} = Gtk2::Gdk::Cursor->new ('hand2')
						unless $self->{cursor};
					$cursor = $self->{cursor};

					# We also need to throw the cell-enter event from here
					# Note: Only hyperlinked cells should throw the cell-enter and leave events
					if ($treemaker_self->{signals}->{'cell-enter'}) {
					    &{$treemaker_self->{signals}->{'cell-enter'}}
							($treemaker_self, $path, $column->{column_number})
								unless $self->{'cell-hovered'};
						$self->{'cell-hovered'} = TRUE;
					}

				} else {
					# Throw the cell-leave event here
					if ($treemaker_self->{signals}->{'cell-leave'}) {
						&{$treemaker_self->{signals}->{'cell-leave'}}
							($treemaker_self, $path, $column->{column_number})
								if $self->{'cell-hovered'};
						$self->{'cell-hovered'} = FALSE;                        	
					}
				}
			}
			$event->window->set_cursor ($cursor);
			return 0;
		}
	); 


	$tree_view_full->signal_connect('button-press-event' =>
		sub {        
			my ($self, $event) = @_;
			my ($path, $column, $cell_x, $cell_y) = $self->get_path_at_pos ($event->x, $event->y);
			my $cursor = undef;
			if ($path && defined $column->{hyperlinked}) {
				my $model = $self->get_model;
				my $hyperlinked = $model->get ($model->get_iter ($path), $column->{hyperlinked});
				if ($hyperlinked) {
					if ($treemaker_self->{signals}->{'cell-clicked'}){
						&{$treemaker_self->{signals}->{'cell-clicked'}}
							($treemaker_self, $path, $column->{column_number});
					}
				}
			}
			$event->window->set_cursor ($cursor);
			return 0;
		}
	); 

}

sub set_selection_mode {
	my ($self, $mode) = @_;
	$self->{tree_view_full}->get_selection->set_mode($mode);
	$self->{tree_view_frozen}->get_selection->set_mode($mode);
}

sub clear_model {
	my ($self) = @_;
	$self->{tree_store_full}->clear;
	$self->{tree_store_frozen}->clear;
}

=head2 Gtk2::Ex::TreeMaker->build_model

This is the core recursive method that actually builds the tree. 

=cut

sub build_model {
	my ($self) = @_;
	$self->clear_model;
	foreach my $subtree (@{$self->{data_tree}->{'Node'}}) {
		$self->_append_children($self->{tree_view_full}->get_model(), undef, 
					$subtree, $self->{column_names});
		$self->_append_children($self->{tree_view_frozen}->get_model(), undef, 
					$subtree, $self->{frozen_column});
	}
	# Expand the tree to start with
	$self->{tree_view_frozen}->expand_all;
	$self->{tree_view_full}->expand_all;
}

=head2 Gtk2::Ex::TreeMaker->get_widget

Returns the widget that you can later attach to a root window or any other container.

=cut

sub get_widget {
	my ($self) = @_;
	# Add the frozen-tree to the left side of the pane 
	my $display_paned = Gtk2::HPaned->new;
	$display_paned->add1 ($self->{tree_view_frozen});

	# we set the vertical size request very small, and it will fill up the
	# available space when we set the default size of the window.
	$self->{tree_view_frozen}->set_size_request (-1, 10);

	# Add the full-tree to a scrolled window in the right pane
	my $scroll = Gtk2::ScrolledWindow->new;
	$scroll->add ($self->{tree_view_full});
	$display_paned->add2 ($scroll);

	# Synchronize the scrolling
	$self->{tree_view_frozen}->set(vadjustment => $self->{tree_view_full}->get_vadjustment);

	return $display_paned;
}

# Private method to enable the freezepane.
sub _synchronize_trees {
	my ($tree_view_frozen, $tree_view_full) = @_;

	# First, we will synchronize the row-expansion/collapse
	$tree_view_frozen->signal_connect('row-expanded' =>
		sub {
			my ($view, $iter, $path) = @_;
			$tree_view_full->expand_row($path,0);
		}
	); 
	$tree_view_frozen->signal_connect('row-collapsed' =>
		sub {
			my ($view, $iter, $path) = @_;
			$tree_view_full->collapse_row($path);
		}
	); 

	# Next, we will synchronize the row selection
	$tree_view_frozen->get_selection->signal_connect('changed' =>
		sub {
			my ($selection) = @_;
			_synchronize_tree_selection($tree_view_frozen, $tree_view_full, $selection);
		}
	); 
	$tree_view_full->get_selection->signal_connect('changed' =>
		sub {
			my ($selection) = @_;
			_synchronize_tree_selection($tree_view_full, $tree_view_frozen, $selection);
		}
	); 
}


# Synchronize the tree selections
sub _synchronize_tree_selection {
	my ($thisview, $otherview, $this_selection) = @_;
	return unless ($thisview and $otherview and $this_selection);
	my ($selected_model, $selected_iter) = $this_selection->get_selected;
	return unless ($selected_model and $selected_iter);
	$otherview->get_selection->select_path ($selected_model->get_path($selected_iter));
}

sub _append_children {
	my ($self, $tree_store, $iter, $data_tree, $columns) = @_;
	if ($data_tree ) {   
		my $count = 0;  
		if ($data_tree->{'Node'}) {
			my $child_iter = $tree_store->append ($iter);
			for my $column(@$columns) {
				my $column_name = $column->{ColumnName};

				# Ignore the real name of the first column. Use the special value called 'Name'
				# so that the tree traversal is correct.
				$column_name = 'Name' if ($count == 0);

				if ($data_tree->{$column_name}) {
					$tree_store->set($child_iter, $count, $data_tree->{$column_name});
				}
				$count+=$#{@{$self->{data_attributes}}}+1;
			}
			foreach my $child(@{$data_tree->{'Node'}}) {
				$self->_append_children($tree_store, $child_iter, $child, $columns);
			}
		} else {
			for my $column(@$columns) {
				my $column_name = $column->{ColumnName};
				next unless ($column_name);
				if ($data_tree->{'Name'} eq $column_name) {
					foreach my $attr (@{$self->{data_attributes}}) {
						foreach my $key (keys %$attr) {
							$tree_store->set($iter, $count++, $data_tree->{$key});
						}
					}
				}
				$count += $#{@{$self->{data_attributes}}}+1;
			}
		}

	}
}

sub _create_columns {
	my ($self, $all_columns, $tree_store, $tree_view )=@_;
	my $column_count = 0;
	my $column_number = 0;
	for my $column (@$all_columns) {
		my $column_name =  $column->{ColumnName};
		my $cell = Gtk2::CellRendererText->new;

		# Align all cells to the right
		$cell->set (xalign => 1);

		# Create a new variable.
		# Else it will always be set to max value of column_count
		# Reference issues
		my $column_id = $column_count;

		# Handle the edits. This is currently half baked.
		$cell->signal_connect (edited => 
			sub {
				my ($cell, $pathstring, $newtext) = @_;
				my $path = Gtk2::TreePath->new_from_string ($pathstring);
				my $iter = $tree_store->get_iter ($path);               
				$tree_store->set ($iter, $column_id, $newtext);

				# Call the call-back hook specified
				# Hey watch out for a division by zero !!! :) Come back later and fix it...
				if ($self->{signals}->{'cell-edited'}){
					&{$self->{signals}->{'cell-edited'}}
						($self, $path, $column_id/($#{@{$self->{data_attributes}}}+1), $newtext);
				}
			}
		);

		my @column_attr;
		my $count=0;
		my $attr_pos_hyperlinked;
		foreach my $attr (@{$self->{data_attributes}}) {
			foreach my $key (keys %$attr) {         	
				# The custom attributes that we created should not be passed 
				# on to the CellRendererText. Either remove them or replace them with
				# something that makes sense to the CellRendererText
				if ($key eq 'hyperlinked') {
					$key = 'underline';
					$attr_pos_hyperlinked = $column_count + $count;
				}            
				push @column_attr, $key;
				push @column_attr, $column_count + $count++;
			}
		}

		my $column = Gtk2::TreeViewColumn->new_with_attributes(
							$column_name, $cell, text => $column_count, @column_attr);
		$column->set_title($column_name);

		# Keep a ref to the $column for later use.
		push @{$self->{treeview_columns}}, $column;

		# Keep this for later; the TreeViewColumn doesn't allow us to
		# query the attribute list, so we have to keep this information
		# for ourselves.
		if (defined $attr_pos_hyperlinked) {
			$column->{hyperlinked} = $attr_pos_hyperlinked;
		}
		$column->{column_number} = $column_number++;

		$column->set_resizable(TRUE);
		$tree_view->append_column($column);

		# Hide the first column
		# Ensure that the expander is fixed to the first column 
		# (and hence is hidden too)
		if ($column_count == 0) {
			$column->set_visible(FALSE);
			$tree_view->set_expander_column($column);
		}
		$column_count+=$#{@{$self->{data_attributes}}}+1;
	}
}

=head2 Gtk2::Ex::TreeMaker->locate_record(Gtk2::TreePath, Integer, Text)

This sub maps a TreeCell location into a flat record in the original recordset that was used to create this tree. The location of the TreeCell itself is denoted using two arguments, the Gtk2::TreePath that points to the row and the Column_ID that points to the column.

Using this information, the function then traverses the internal data structure and returns a record (an array object).

=cut

sub locate_record {
	my ($self, $edit_path, $column_id) = @_; 
	my $record;

	# Drill down the $tree_path and keep adding entries into the record
	my $temp = $self->{data_tree};
	my @tree_path = split /:/, $edit_path->to_string; 
	for (my $i=0; $i<=$#tree_path; $i++) {
		my $index = $tree_path[$i];
		$temp = _get_subtree($temp, $index);
		push @$record, $temp->{'Name'};
	}
	my $column_name = $self->{column_names}->[$column_id]->{'ColumnName'};   
	# Now the hierarchical tree elements have been added into the record
	# Next we just need to add the correct column_name
	push @$record, $column_name;
	foreach my $node (@{$temp->{'Node'}}) {
		if ($node->{'Name'} eq $column_name) {
			push @$record, $node;
		}
	}
	return $record;
}

sub _get_subtree {
	my ($tree, $index) = @_;
	my $count = 0;
	foreach my $rec (@{$tree->{'Node'}}) {
		if (exists $rec->{'Node'}) {
			if ($count == $index) {
				return $rec;
			}	
			$count++ ;
		}
	}
}

1;

__END__

=head1 TODO

Here is a list of stuff that I plan to add to this module.

=over 3

=item * Wake Up ! Add some more tests.

=back

=head1 AUTHOR

Ofey Aikon, C<< <ofey.aikon at gmail dot com> >>

=head1 BUGS

You tell me. Send me an email !

=head1 ACKNOWLEDGEMENTS

To the wonderful gtk-perl-list.

=head1 COPYRIGHT & LICENSE

Copyright 2004 Ofey Aikon, All Rights Reserved.

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 59
Temple Place - Suite 330, Boston, MA  02111-1307  USA.

=cut
