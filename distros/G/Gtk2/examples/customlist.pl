# ported from Tim-Phillip Mueller's Tree View tutorial,
# http://scentric.net/tutorial/sec-custom-models.html
#

package CustomList;

use Glib qw(TRUE FALSE);
use Gtk2;
use Carp;
use Data::Dumper;
use strict;
use warnings;

# maybe bad style, but makes life a lot easier
use base Exporter::;

our @EXPORT = qw/
	CUSTOM_LIST_COL_RECORD
	CUSTOM_LIST_COL_NAME
	CUSTOM_LIST_COL_YEAR_BORN
	CUSTOM_LIST_N_COLUMNS
/;

# The data columns that we export via the tree model interface

use constant {
	CUSTOM_LIST_COL_RECORD    => 0,
	CUSTOM_LIST_COL_NAME      => 1,
	CUSTOM_LIST_COL_YEAR_BORN => 2,
	CUSTOM_LIST_N_COLUMNS     => 3,
};

#
#  here we register our new type and its interfaces with the type system.
#  If you want to implement additional interfaces like GtkTreeSortable,
#  you will need to do it here.
#

use Glib::Object::Subclass
	Glib::Object::,
	interfaces => [ Gtk2::TreeModel:: ],
	;

#
# this is called everytime a new custom list object
# instance is created (we do that in custom_list_new).
# Initialise the list structure's fields here.
#

sub INIT_INSTANCE {
	my $self = shift;
	$self->{n_columns} = CUSTOM_LIST_N_COLUMNS;
	$self->{column_types} = [
		'Glib::Scalar',	# CUSTOM_LIST_COL_RECORD
		'Glib::String',	# CUSTOM_LIST_COL_NAME
		'Glib::Uint',	# CUSTOM_LIST_COL_YEAR_BORN
	];
	$self->{rows}     = [];

	# Random int to check whether an iter belongs to our model
	$self->{stamp} = sprintf '%d', rand (1<<31);
}


#
#  this is called just before a custom list is
#  destroyed. Free dynamically allocated memory here.
#

sub FINALIZE_INSTANCE {
	my $self = shift;

	# free all records and free all memory used by the list
	#warning IMPLEMENT
}


#
# tells the rest of the world whether our tree model has any special
# characteristics. In our case, we have a list model (instead of a tree).
# Note that unlike the C version of this custom model, our iters do NOT
# persist.
#

#sub GET_FLAGS { [qw/list-only iters-persist/] }
sub GET_FLAGS { [qw/list-only/] }


#
# tells the rest of the world how many data
# columns we export via the tree model interface
#

sub GET_N_COLUMNS { shift->{n_columns}; }


#
# tells the rest of the world which type of
# data an exported model column contains
#

sub GET_COLUMN_TYPE {
	my ($self, $index) = @_;
	# and invalid index will send undef back to the calling XS layer,
	# which will croak.
	return $self->{column_types}[$index];
}


#
# converts a tree path (physical position) into a
# tree iter structure (the content of the iter
# fields will only be used internally by our model).
# We simply store a pointer to our CustomRecord
# structure that represents that row in the tree iter.
#

sub GET_ITER {
	my ($self, $path) = @_;

	die "no path" unless $path;

	my @indices = $path->get_indices;
	my $depth   = $path->get_depth;

	# we do not allow children
	# depth 1 = top level; a list only has top level nodes and no children
	die "depth != 1" unless $depth == 1;

	my $n = $indices[0]; # the n-th top level row

	return undef if $n >= @{$self->{rows}} || $n < 0;

	my $record = $self->{rows}[$n];

	die "no record" unless $record;
	die "bad record" unless $record->{pos} == $n;

	# We simply store a pointer to our custom record in the iter
	return [ $self->{stamp}, $n, $record, undef ];
}


#
#  custom_list_get_path: converts a tree iter into a tree path (ie. the
#                        physical position of that row in the list).
#

sub GET_PATH {
	my ($self, $iter) = @_;
	die "no iter" unless $iter;

	my $record = $iter->[2];

	my $path = Gtk2::TreePath->new;
	$path->append_index ($record->{pos});
	return $path;
}


#
# custom_list_get_value: Returns a row's exported data columns
#                        (_get_value is what gtk_tree_model_get uses)
#

sub GET_VALUE {
	my ($self, $iter, $column) = @_;

	die "bad iter" unless $iter;

	return undef unless $column < @{$self->{column_types}};

	my $record = $iter->[2];

	return undef unless $record;

	die "bad iter" if $record->{pos} >= @{$self->{rows}};

	if ($column == CUSTOM_LIST_COL_RECORD) {
		return $record;
	} elsif ($column == CUSTOM_LIST_COL_NAME) {
		return $record->{name};
	} elsif ($column == CUSTOM_LIST_COL_YEAR_BORN) {
		return $record->{year_born};
	}
}


#
# iter_next: Takes an iter structure and sets it to point to the next row.
#

sub ITER_NEXT {
	my ($self, $iter) = @_;

	return undef
		unless $iter && $iter->[2];

	my $record = $iter->[2];

	# Is this the last record in the list?
	return undef
		if $record->{pos} >= @{ $self->{rows} };

	my $nextrecord = $self->{rows}[$record->{pos} + 1];

	return undef unless $nextrecord;
	die "invalid record" unless $nextrecord->{pos} == ($record->{pos} + 1);

	return [ $self->{stamp}, $nextrecord->{pos}, $nextrecord, undef ];
}


#
# iter_children: Returns TRUE or FALSE depending on whether the row
#                specified by 'parent' has any children.  If it has
#                children, then 'iter' is set to point to the first
#                child.  Special case: if 'parent' is undef, then the
#                first top-level row should be returned if it exists.
#

sub ITER_CHILDREN {
	my ($self, $parent) = @_;

###	return undef unless $parent and $parent->[1];

	# this is a list, nodes have no children
	return undef if $parent;

	# parent == NULL is a special case; we need to return the first top-level row

 	# No rows => no first row
	return undef unless @{ $self->{rows} };

	# Set iter to first item in list
	return [ $self->{stamp}, 0, $self->{rows}[0] ];
}


#
# iter_has_child: Returns TRUE or FALSE depending on whether
#                 the row specified by 'iter' has any children.
#                 We only have a list and thus no children.
#

sub ITER_HAS_CHILD { FALSE }

#
# iter_n_children: Returns the number of children the row specified by
#                  'iter' has. This is usually 0, as we only have a list
#                  and thus do not have any children to any rows.
#                  A special case is when 'iter' is undef, in which case
#                  we need to return the number of top-level nodes, ie.
#                  the number of rows in our list.
#

sub ITER_N_CHILDREN {
	my ($self, $iter) = @_;

	# special case: if iter == NULL, return number of top-level rows
	return scalar @{$self->{rows}}
		if ! $iter;

	return 0; # otherwise, this is easy again for a list
}


#
# iter_nth_child: If the row specified by 'parent' has any children,
#                 set 'iter' to the n-th child and return TRUE if it
#                 exists, otherwise FALSE.  A special case is when
#                 'parent' is NULL, in which case we need to set 'iter'
#                 to the n-th row if it exists.
#

sub ITER_NTH_CHILD {
	my ($self, $parent, $n) = @_;

	# a list has only top-level rows
	return undef if $parent;

	# special case: if parent == NULL, set iter to n-th top-level row

	return undef if $n >= @{$self->{rows}};

	my $record = $self->{rows}[$n];

	die "no record" unless $record;
	die "bad record" unless $record->{pos} == $n;

	return [ $self->{stamp}, $n, $record ];
}


#
# iter_parent: Point 'iter' to the parent node of 'child'.  As we have a
#              a list and thus no children and no parents of children,
#              we can just return FALSE.
#

sub ITER_PARENT { FALSE }

#
# ref_node and unref_node get called as the model manages the lifetimes
# of nodes in the model.  you normally don't need to do anything for these,
# but may want to if you plan to implement data caching.
#
#sub REF_NODE { warn "REF_NODE @_\n"; }
#sub UNREF_NODE { warn "UNREF_NODE @_\n"; }

#
# new:  This is what you use in your own code to create a
#       new custom list tree model for you to use.
#

# we inherit new from Glib::Object::Subclass


#
# set: It's always nice to be able to update the data stored in a data
#      structure.  So, here's a method to let you do that.  We emit the
#      'row-changed' signal to notify all who care that we've updated
#      something.
#

sub set {
	my $self     = shift;
	my $treeiter = shift;

	# create (col, value) pairs to update.
	my %vals     = @_;

	# Convert the Gtk2::TreeIter to a more useable array reference.
	# Note that the model's stamp must be passed in as an argument.
	# This is so we can avoid trying to extract the guts of an iter
	# that we did not create in the first place.
	my $iter = $treeiter->to_arrayref($self->{stamp});
	
	my $record = $iter->[2];

	while (my ($col, $val) = each %vals) {
		if ($col == CUSTOM_LIST_COL_NAME) {
			$record->{name} = $val;
		} elsif ($col == CUSTOM_LIST_COL_YEAR_BORN) {
			$record->{year_born} = $val;
		} elsif ($col == CUSTOM_LIST_COL_RECORD) {
			warn "Can't update the value of the Record column!";
		} else {
			warn "Invalid column used in set method!";
		}
	}

	$self->row_changed ($self->get_path ($treeiter), $treeiter);
}

#
# get_iter_from_name: Sometimes, you have a bit of information that
#                     uniquely identifies a record in your TreeModel,
#                     but it doesn't convert easily to a TreePath,
#                     so it's hard to get a TreeIter out of it.  This
#                     is an example of how to make a TreeModel that
#                     can get iterators without having to find the path
#                     first.
#

sub get_iter_from_name {
	my $self = shift;
	my $name   = shift;

	my ($record, $n);

	for (0..scalar (@{$self->{rows}})) {
		if ($self->{rows}[$_]->{name} eq $name) {
			$record = $self->{rows}[$_];
			$n      = $_;
			last;
		}
	}

	return Gtk2::TreeIter->new_from_arrayref([$self->{stamp}, $n, $record, undef]);
}

#
# append_record:  Empty lists are boring. This function can be used in your
#                 own code to add rows to the list.  Note how we emit the
#                 "row-inserted" signal after we have appended the row
#                 so the tree view and other interested objects know about
#                 the new row.
#

sub append_record {
	my ($self, $name, $year_born) = @_;

	croak "usage: \$list->append_record (NAME, YEAR_BORN)"
  		unless $name;

	my $newrecord = {
		name => $name,
#		name_collate_key => g_utf8_collate_key(name,-1), # for fast sorting, used later
		year_born => $year_born,
	};

	push @{ $self->{rows} }, $newrecord;
	$newrecord->{pos} = @{$self->{rows}} - 1;

	# inform the tree view and other interested objects
	# (e.g. tree row references) that we have inserted
	# a new row, and where it was inserted

	my $path = Gtk2::TreePath->new;
	$path->append_index ($newrecord->{pos});
	$self->row_inserted ($path, $self->get_iter ($path));
}

############################################################################
############################################################################
############################################################################

package main;

no strict 'subs';
use Glib qw(TRUE FALSE);
use Gtk2 -init;

import CustomList;

sub fill_model {
	my $customlist = shift;

	my @firstnames = qw(Joe Jane William Hannibal Timothy Gargamel);
	my @surnames   = qw(Grokowich Twitch Borheimer Bork);

	foreach my $sname (@surnames) {
		foreach my $fname (@firstnames) {
			$customlist->append_record ("$fname $sname",
			                            1900 + rand (103.0))
		}
	}
}

sub create_view_and_model {
  my $customlist = CustomList->new;
  fill_model ($customlist);

  my $view = Gtk2::TreeView->new ($customlist);

  my $renderer = Gtk2::CellRendererText->new;
  my $col = Gtk2::TreeViewColumn->new;

  $col->pack_start ($renderer, TRUE);
  $col->add_attribute ($renderer, text => &CustomList::CUSTOM_LIST_COL_NAME);
  $col->set_title ("Name");
  $view->append_column ($col);
  $renderer->set (editable => TRUE);
  $renderer->signal_connect (edited => sub {
         my ($cell, $pathstring, $newtext, $model) = @_;
         my $path = Gtk2::TreePath->new_from_string ($pathstring);
         my $iter = $model->get_iter ($path);
         $model->set ($iter, &CustomList::CUSTOM_LIST_COL_NAME, $newtext);
  }, $customlist);

  $renderer = Gtk2::CellRendererText->new;
  $col = Gtk2::TreeViewColumn->new;
  $col->pack_start ($renderer, TRUE);
  $col->add_attribute ($renderer, text => &CustomList::CUSTOM_LIST_COL_YEAR_BORN);
  $col->set_title ("Year Born");
  $view->append_column ($col);

  return $view;
}

{
  my $window = Gtk2::Window->new;
  $window->set_default_size (200, 400);
  $window->signal_connect (delete_event => sub {Gtk2->main_quit; 0});

  my $view = create_view_and_model();
  my $scrollwin = Gtk2::ScrolledWindow->new;
  $scrollwin->add ($view);
  $window->add ($scrollwin);

  $window->show_all;

  Gtk2->main;

  exit 0;
}


############################################################################
############################################################################
############################################################################
