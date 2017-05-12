package Gtk2::Ex::FormFactory::CheckButtonGroup;

use Carp;
use strict;

use base qw( Gtk2::Ex::FormFactory::Widget );
use POSIX qw(ceil);

sub get_type { "check_button_group" }

sub get_max_columns		{ shift->{max_columns}			}
sub get_max_rows		{ shift->{max_rows}			}
sub get_attr_max_columns	{ shift->{attr_max_columns}		}
sub get_attr_max_rows		{ shift->{attr_max_rows}		}
sub get_column_labels		{ shift->{column_labels}		}
sub get_attr_column_labels	{ shift->{attr_column_labels}		}
sub get_row_labels		{ shift->{row_labels}			}
sub get_attr_row_labels		{ shift->{attr_row_labels}		}
sub get_homogeneous		{ shift->{homogeneous}			}

sub set_max_columns		{ shift->{max_columns}		= $_[1]	}
sub set_max_rows		{ shift->{max_rows}		= $_[1]	}
sub set_attr_max_columns	{ shift->{attr_max_columns}	= $_[1]	}
sub set_attr_max_rows		{ shift->{attr_max_rows}	= $_[1]	}
sub set_column_labels		{ shift->{column_labels}	= $_[1]	}
sub set_attr_column_labels	{ shift->{attr_column_labels}	= $_[1]	}
sub set_row_labels		{ shift->{row_labels}		= $_[1]	}
sub set_attr_row_labels		{ shift->{attr_row_labels}	= $_[1]	}
sub set_homogeneous		{ shift->{homogeneous}		= $_[1]	}

sub get_gtk_check_buttons	{ shift->{gtk_check_buttons}		}
sub get_gtk_table		{ shift->{gtk_table}			}

sub set_gtk_check_buttons	{ shift->{gtk_check_buttons}	= $_[1]	}
sub set_gtk_table		{ shift->{gtk_table}		= $_[1]	}

sub get_last_toggled_value	{ shift->{last_toggled_value}		}
sub set_last_toggled_value	{ shift->{last_toggled_value}	= $_[1]	}

sub get_in_selection_update	{ shift->{in_selection_update}		}
sub set_in_selection_update	{ shift->{in_selection_update}	= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($max_columns, $max_rows, $attr_max_columns, $attr_max_rows) =
	@par{'max_columns','max_rows','attr_max_columns','attr_max_rows'};
	my  ($column_labels, $attr_column_labels, $row_labels) =
	@par{'column_labels','attr_column_labels','row_labels'};
	my  ($attr_row_labels, $homogeneous) =
	@par{'attr_row_labels','homogeneous'};

	my $self = $class->SUPER::new(@_);

	$max_rows = 1 if ($max_rows == 0 && $max_columns == 0) &&
			 !($attr_max_rows || $attr_max_columns);
	
	$homogeneous = 1 if not defined $homogeneous;
	
	$self->set_max_columns 		($max_columns);
	$self->set_max_rows 		($max_rows);
	$self->set_attr_max_columns	($attr_max_columns);
	$self->set_attr_max_rows 	($attr_max_rows);
	$self->set_column_labels  	($column_labels); 
	$self->set_attr_column_labels 	($attr_column_labels);
	$self->set_row_labels 		($row_labels);
	$self->set_attr_row_labels 	($attr_row_labels);
	$self->set_homogeneous 		($homogeneous);

	return $self;
}

sub cleanup {
	my $self = shift;
	
	$self->SUPER::cleanup(@_);
	
	$self->set_gtk_check_buttons(undef);
	$self->set_gtk_table(undef);

	1;
}

sub object_to_widget {
	my $self = shift;
	
	#-- $checkboxes = [ [0, "Sun"], [1 ,"Mon"], [2,"Tue"], ... ]
	my $checkboxes = $self->get_proxy->get_attr_list(
		$self->get_attr, $self->get_name
	);

	#-- $selected_href = { 0 => 1, 2 => 1 }  - Sun and Tue are selected
	my $selected_href = $self->get_object_value;
	
	my $hbox = $self->get_gtk_widget;
	my @children = $hbox->get_children;
	$hbox->remove($_) for @children;

	my ($rows, $columns);
	my $max_rows      = $self->get_max_rows;
	my $max_columns   = $self->get_max_columns;
	my $row_labels    = $self->get_row_labels;
	my $column_labels = $self->get_column_labels;

	my $cnt = @{$checkboxes};

	if ( $self->get_attr_max_rows ) {
		$max_rows = $self->get_proxy->get_attr($self->get_attr_max_rows);
	} elsif ( $self->get_attr_max_columns ) {
		$max_columns = $self->get_proxy->get_attr($self->get_attr_max_columns);
	}

	if ( $self->get_attr_row_labels ) {
		$row_labels = $self->get_proxy->get_attr($self->get_attr_row_labels);
	}
	
	if ( $self->get_attr_column_labels ) {
		$column_labels = $self->get_proxy->get_attr($self->get_attr_column_labels);
	}

	if ( $max_rows ) {
		$rows = $max_rows;
		$rows = $cnt if $rows > $cnt;
		$columns = ceil($cnt / $rows);
	} else {
		$columns = $max_columns;
		$columns = $cnt if $columns > $cnt;
		$rows = ceil($cnt / $columns);
	}

	my %gtk_check_buttons;
	my $gtk_table = Gtk2::Table->new ($rows, $columns);
	$gtk_table->set ( homogeneous => $self->get_homogeneous );
	
	++$columns if $row_labels;
	++$rows    if $column_labels;
	
	my $i = 0;
	for ( my $c=0; $c < $columns && $i < $cnt; ++$c ) {
		for ( my $r=0; $r < $rows && $i < $cnt; ++$r ) {
			next if $column_labels && $c == 0 && $r == 0;
			if ( $row_labels && $c==0 && $r > 0 ) {
			    my $gtk_label = Gtk2::Label->new($row_labels->[$r-1]);
			    $gtk_table->attach_defaults($gtk_label, $c, $c+1, $r, $r+1);
			    next;
			}
			if ( $column_labels && $r==0 && $c > 0 ) {
			    my $gtk_label = Gtk2::Label->new($column_labels->[$c-1]);
			    $gtk_table->attach_defaults($gtk_label, $c, $c+1, $r, $r+1);
			    next;
			}
			my $checkbox = $checkboxes->[$i];
			my $gtk_check_button = Gtk2::CheckButton->new($checkbox->[1]);
			$gtk_check_buttons{$checkbox->[0]} = $gtk_check_button;
			$gtk_check_button->set_active(1) if $selected_href->{$checkbox->[0]};
			$gtk_table->attach_defaults($gtk_check_button, $c, $c+1, $r, $r+1);
			++$i;
		}
	}

	$hbox->pack_start($gtk_table, 0, 1, 0);
	$hbox->show_all;

	$self->set_gtk_check_buttons(\%gtk_check_buttons);
	$self->set_gtk_table($gtk_table);

	$self->connect_changed_signal_for_all_buttons;

	1;
}

sub update_selection {
	my $self = shift;
	
	$self->set_in_selection_update(1);
	
	my $selected_href     = $self->get_object_value;
	my $gtk_check_buttons = $self->get_gtk_check_buttons;
	
	while ( my ($value, $gtk_check_button) = each %{$gtk_check_buttons} ) {
		$gtk_check_button->set_active( $selected_href->{$value} );
	}
	
	$self->set_in_selection_update(0);

	1;
}

sub widget_to_object {
	my $self = shift;
	
	return if $self->get_in_selection_update;

	my $gtk_check_buttons = $self->get_gtk_check_buttons;
	my %selected;
	
	while ( my ($value, $gtk_check_button) = each %{$gtk_check_buttons} ) {
		$selected{$value} = 1 if $gtk_check_button->get_active;
	}
	
	$self->set_object_value(\%selected);

	1;
}

sub connect_changed_signal_for_all_buttons {
	my $self = shift;
	
	my $gtk_check_buttons = $self->get_gtk_check_buttons;
	
	while ( my ($value, $gtk_check_button) = each %{$gtk_check_buttons} ) {
		$gtk_check_button->signal_connect ( toggled => sub {
			return 1 if $self->get_in_selection_update;
			$self->set_last_toggled_value($value);
			$self->widget_value_changed;
			1;
		} );
	}

	1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::CheckButtonGroup - A group of checkbuttons

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::CheckButtonGroup->new (
    max_columns        => Maximum number of columns,
    max_rows           => Maximum number of rows,
    column_labels      => Array of column label strings,
    row_labels	       => Array of row label strings,

    attr_max_columns   => Object attribute for number of columns,
    attr_max_rows      => Object attribute for number of rows,
    attr_column_labels => Object attribute for column labels,
    attr_row_labels    => Object attribute for row labels,

    homogeneous	       => Force homogeneous layout of underlying table?
    ...
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements a group of check buttons which allow
a multiple selection out of a set from predefined values.
It's arranged in a two dimensional table. You can specify
either the maximum number of rows or columns, the actual
dimensions are calculated automatically.

Optionally you can add column and/or row labels, extending
the corresponding table accordingly.

You can pass the configuration data statically or specify
application object attributes controlling them, so the
checkbutton group builds dynamically at runtime.

The value of a CheckBoxGroup is a hash. The value of each
selected checkbox will result in a correspondent hash key
with a true value assigned.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::CheckButtonGroup

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

=item B<max_columns> = SCALAR [optional]

Maximum number of columns the table should have. You must not set
B<max_rows> when you specify B<max_columns>.

=item B<max_rows> = SCALAR [optional]

Maximum number of rows the table should have. You must not set
B<max_columns> when you specify B<max_rows>. If you omit both
attributes B<max_rows> defaults to 1, so all buttons will appear
in one row.

=item B<column_labels> = ARRAY [optional]

You can add column labels by setting an array of strings
to the B<column_labels> attribute. The number of entries
should correspond to the B<max_columns> setting.

=item B<row_labels> = ARRAY [optional]

You can add row labels by setting an array of strings
to the B<row_labels> attribute. The number of entries
should correspond to the B<max_rows> setting.

=item B<attr_max_columns> = "object.attr" [optional]

As an alternative to B<max_columns> the maximum number of
columns may be controlled by an application object attribute
which needs to be passed here in "object.attr" notation.

=item B<attr_max_rows> = "object.attr" [optional]

As an alternative to B<max_rows> the maximum number of
rows may be controlled by an application object attribute
which needs to be passed here in "object.attr" notation.

=item B<attr_column_labels> = "object.attr" [optional]

As an alternative to B<column_labels> the column labels
may be controlled by an application object attribute
which needs to be passed here in "object.attr" notation.

=item B<attr_row_labels> = "object.attr" [optional]

As an alternative to B<row_labels> the row labels
may be controlled by an application object attribute
which needs to be passed here in "object.attr" notation.

=item B<homogeneous> = BOOL [optional]

Defaults to 1 forcing the underlying table to
homogeneous layout.

=back

=head1 REQUIREMENTS FOR ASSOCIATED APPLICATION OBJECTS

Application objects represented by a Gtk2::Ex::FormFactory::CheckButtonGroup
must define additional methods. The naming of the methods listed
beyond uses the standard B<get_> prefix for the attribute read
accessor. B<ATTR> needs to be replaced by the actual name of
the attribute associated with the widget.

=over 4

=item B<get_ATTR_list>

This method must return a two dimensional array resp. a list 
of lists which represent the values the user can select from.

Example:

  [
    [ 0, "Sun" ],
    [ 1, "Mon" ],
    [ 2, "Tue" ],
    ...
  ]

Each entry in the list consists of a list ref with two elements.
The first is the value associated with the checkbox (which will
become a hash key in the associated object attribute), the second
the label of the checkbox on the GUI.

=back

For more attributes refer to L<Gtk2::Ex::FormFactory::Widget>.

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
