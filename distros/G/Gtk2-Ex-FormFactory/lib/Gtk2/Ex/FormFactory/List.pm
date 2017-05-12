package Gtk2::Ex::FormFactory::List;

use strict;
use Carp;

use base qw( Gtk2::Ex::FormFactory::Widget );

sub get_type { "list" }

sub get_attr_select		{ shift->{attr_select}			}
sub get_attr_select_column	{ shift->{attr_select_column}		}
sub get_update_selection_only	{ shift->{update_selection_only}	}
sub get_columns			{ shift->{columns}			}
sub get_types			{ shift->{types}			}
sub get_visible			{ shift->{visible}			}
sub get_editable		{ shift->{editable}			}
sub get_selection_mode		{ shift->{selection_mode}		}
sub get_is_editable		{ shift->{is_editable}			}
sub get_selection_backup	{ shift->{selection_backup}		}
sub get_no_header		{ shift->{no_header}			}
sub get_last_applied_selection	{ shift->{last_applied_selection}	}

sub set_attr_select		{ shift->{attr_select}		= $_[1]	}
sub set_attr_select_column	{ shift->{attr_select_column}	= $_[1]	}
sub set_update_selection_only	{ shift->{update_selection_only}= $_[1]	}
sub set_columns			{ shift->{columns}		= $_[1]	}
sub set_types			{ shift->{types}		= $_[1]	}
sub set_visible			{ shift->{visible}		= $_[1]	}
sub set_editable		{ shift->{editable}		= $_[1]	}
sub set_selection_mode		{ shift->{selection_mode}	= $_[1]	}
sub set_is_editable		{ shift->{is_editable}		= $_[1]	}
sub set_selection_backup	{ shift->{selection_backup}	= $_[1]	}
sub set_no_header		{ shift->{no_header}		= $_[1]	}
sub set_last_applied_selection	{ shift->{last_applied_selection}= $_[1]}

sub has_additional_attrs	{ [ "select" ] 				}

sub get_selected_rows {
	my $self = shift;
	my @sel = $self->get_gtk_widget->get_selected_indices;
	return \@sel;
}

sub get_data {
	my $self = shift;
	return $self->get_gtk_widget->{data};
}

sub select_row_by_attr {
	my $self = shift;
	my ($attr_value) = @_;
	
	my $column = $self->get_attr_select_column;
	my $data = $self->get_data;

	for ( my $i=0; $i < @{$data}; ++$i ) {
		if ( $data->[$i][$column] eq $attr_value ) {
			$self->get_gtk_widget->select($i);
			last;
		}
	}
	
	1;		
}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($attr_select, $columns, $types, $editable, $visible) =
	@par{'attr_select','columns','types','editable','visible'};
	my  ($update_selection_only, $selection_mode) =
	@par{'update_selection_only','selection_mode'};
	my  ($attr_select_column, $no_header) =
	@par{'attr_select_column','no_header'};

	croak "'columns' attribute is mandatory" unless $columns;

	my $self = $class->SUPER::new(@_);
	
	$self->set_attr_select	  	($attr_select);
	$self->set_attr_select_column	($attr_select_column);
	$self->set_columns		($columns);
	$self->set_visible		($visible);
	$self->set_types		($types);
	$self->set_editable		($editable);
	$self->set_selection_mode	($selection_mode);
	$self->set_update_selection_only($update_selection_only);
	$self->set_no_header		($no_header);

	my $is_editable = 0;
	map { $is_editable = 1 if $_ } @{$editable};
	
	$self->set_is_editable($is_editable);
	
	return $self;
}

sub object_to_widget {
	my $self = shift;

	my $object_value = $self->get_object_value || [];

	my $slist_was_empty = ! scalar(@{$self->get_gtk_widget->{data}});

	if ( not $self->get_update_selection_only ) {
		$self->get_gtk_widget
		     ->set_data_array($object_value);
	} else {
		$self->get_gtk_widget
		     ->set_data_array($object_value)
			if @{$self->get_gtk_widget->{data}} == 0;
	}

	if ( $self->get_attr_select ) {
		my $proxy = $self->get_proxy;
		my $idx = $proxy->get_attr (
			$self->get_attr_select
		);
		my $sel;
		$sel = join("\t",@{$idx}) if $idx;
		$self->set_last_applied_selection($sel);
		my $gtk_simple_list = $self->get_gtk_widget;
		if ( defined $idx and @{$idx} and @{$self->get_gtk_widget->{data}} != 0 ) {
			if ( defined $self->get_attr_select_column ) {
				my $i = 0;
				my $col  = $self->get_attr_select_column;
				my $data = $self->get_gtk_widget->{data};
				my %col2idx = map { ($_->[$col], $i++) } @{$data};
				my @idx = map { $col2idx{$_} } @{$idx};
				$idx = \@idx;
			}

			if ( @{$idx} && defined $idx->[0] ) {
				$gtk_simple_list->select(@{$idx});
				$gtk_simple_list->scroll_to_cell(
					Gtk2::TreePath->new_from_string($idx->[0]),
					($gtk_simple_list->get_columns)[0],
					0, 0
				) if $slist_was_empty;
			} else {
				$gtk_simple_list->get_selection->unselect_all;
				$proxy->set_attr($self->get_attr_select, undef);
			}
		} else {
			$gtk_simple_list->get_selection->unselect_all;
		}

		Glib::Idle->add (sub {
			$self->widget_selection_to_object;
			0;
		});
	}

	1;
}

sub widget_to_object {
	my $self = shift;
	
	if ( $self->get_is_editable ) {
		my $data = $self->get_gtk_widget->{data};
		my @value = @{$data};
		$self->set_object_value (\@value);
	}

	$self->widget_selection_to_object
		if $self->get_attr_select;
	
	1;
}

sub widget_selection_to_object {
	my $self = shift;
	
	return 1 if ! $self->get_proxy->get_object($self->get_object);
	
	my @sel = $self->get_gtk_widget->get_selected_indices;

	if ( defined $self->get_attr_select_column ) {
		my $column = $self->get_attr_select_column;
		my $data   = $self->get_gtk_widget->{data};
		$_ = $data->[$_][$column] for @sel;
	}

	my $sel = join("\t",@sel);
	return if $sel eq $self->get_last_applied_selection;
	$self->set_last_applied_selection($sel);

	$self->get_proxy->set_attr (
		$self->get_attr_select, \@sel
	); 

	1;
}

sub empty_widget {
	my $self = shift;

	$self->get_gtk_widget->set_data_array([]);
	$self->get_gtk_widget->get_selection->unselect_all;

	1;
}

sub backup_widget_value {
	my $self = shift;

	if ( $self->get_is_editable ) {
		my $data = $self->get_gtk_widget->{data};
		my @value = @{$data};
		$self->set_backup_widget_value (\@value);
	}
	
	if ( $self->get_attr_select ) {
		my @sel = $self->get_gtk_widget->get_selected_indices;
		$self->set_selection_backup(\@sel);
	}

	1;
}

sub restore_widget_value {
	my $self = shift;

	if ( $self->get_is_editable ) {
		$self->get_gtk_widget
		     ->set_data_array($self->get_backup_widget_value||[]);
	}

	if ( $self->get_attr_select ) {
		my $idx = $self->get_selection_backup;
		$self->get_gtk_widget->select(@{$idx});
	}

	1;
}

sub get_widget_check_value {
	$_[0]->get_gtk_widget->{data};
}

sub connect_changed_signal {
	my $self = shift;
	
	if ( $self->get_is_editable ) {
		$self->get_gtk_widget->get_model->signal_connect (
		  'row-changed' => sub { $self->widget_value_changed },
		);
	}
	
	if ( $self->get_attr_select ) {
		$self->get_gtk_widget->get_selection->signal_connect (
		  'changed'	=> sub { $self->widget_value_changed },
		);
	}
	

	1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::List - A List in a FormFactory framework

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::List->new (
    attr_select        => Attribute name for selection tracking,
    attr_select_column => Use this column's value to store in attr_select
    columns            => Titles of the list columns,
    types              => Types of the list columns,
    editable           => Which columns are editable?,
    visible            => Which columns are visible?
    selection_mode     => Selection mode of this list,
    no_header          => Omit header?
    update_selection_only => Boolean, whether updates should only
    			     change the selection, not the list
			     of values,
    ...
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements a List in a Gtk2::Ex::FormFactory framework
(based on Gtk2::Ex::Simple::List). The value of the associated
application object attribute needs to be a reference to a two
dimensional array with the content of the list.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::List

  Gtk2::Ex::FormFactory::Layout
  Gtk2::Ex::FormFactory::Rules
  Gtk2::Ex::FormFactory::Context
  Gtk2::Ex::FormFactory::Proxy

=head1 ATTRIBUTES

Attributes are handled through the common get_ATTR(), set_ATTR()
style accessors, but they are mostly passed once to the object
constructor and must not be altered after the associated FormFactory
was built.

=over 4

=item B<attr_select> = SCALAR [optional]

If you want to track the selection state of the List set the name
of the attribute of the associated application object here. An
array reference with the indicies of the selected rows (or specific
column values if B<attr_select_column> is set) will be managed
automatically and stored in this attribute.

=item B<attr_select_column>

Normally indicies of the selected rows are stored in the attribute
passed with B<attr_select>. Specify a column number here and the
corresponding values will be stored instead (e.g. an internal
database ID of an invisible column). If you use this you may use
the B<select_row_by_attr()> method as well, which is described below.

=item B<columns> = ARRAYREF [mandatory]

This is a reference to an array containing the column titles
of this list.

=item B<types> = ARRAYREF [optional]

You may define types for the columns of the list. The type of a column
defaults to 'text'. Other possible types are:

  text    normal text strings
  markup  pango markup strings
  int     integer values
  double  double-precision floating point values
  bool    boolean values, displayed as toggle-able checkboxes
  scalar  a perl scalar, displayed as a text string by default
  pixbuf  a Gtk2::Gdk::Pixbuf

=item B<editable> = ARRAYREF [optional]

This an array reference of boolean values, one value for
each column. Changes to columns marked editable are synchronized
automatically with the associated application object attribute.

=item B<visible> = ARRAYREF [optional]

This an array reference of boolean values, one value for
each column and controls the visibility of the corresponding columns.
Default is to display all columns.

=item B<selection_mode> = 'none'|'single'|'browse'|'multiple' [optional]

You may specify a selection mode for the list. Please refer to
the Gtk+ documentation of GtkSelectionMode for details about
the possible selection modes.

=item B<update_selection_only> = BOOL [optional]

If you know the values of your list don't change at runtime, and
only the actual selection is important, you should set this to
a true value, because updating will be significantly faster,
since only the actual selection is affected.

=back

For more attributes refer to L<Gtk2::Ex::FormFactory::Widget>.

=head1 METHODS

=over 4

=item $rows = $widget->B<get_selected_rows> ()

Returns a list reference of selected row indicies.

=item $data_lref = $widget->B<get_data> ()

Returns the data array of the underlying Gtk2::SimpleList. It's
a two dimensional array of rows and columns. All manipulations
affect the GUI immediately but bypasses all Gtk2::Ex::FormFactory
automatic object value update magic, so be careful with this.

=item $widget->B<select_row_by_attr> ($value)

Selects a row by a given B<select_attr> attribute value. Works
only if B<select_attr> is set for this list.

=back

=head1 AUTHORS

 Jörn Reder <joern at zyn dot de>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2006 by Jörn Reder.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Library General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307
USA.

=cut
