=pod

=head1 NAME

ETL::Pipeline::Input::Tabular - Sequential input in rows and columns

=head1 SYNOPSIS

  # In the input source...
  use Moose;
  with 'ETL::Pipeline::Input::Tabular';
  ...

=head1 DESCRIPTION

B<ETL::Pipeline::Input::Tabular> provides a common interface where the data
is in a table or columns. Spreadsheets and CSV files are considered I<tabular>.

While B<ETL::Pipeline::Input::Tabular> works with any sequential input source,
L<ETL::Pipeline::Input::File>s would be the most common.

=cut

package ETL::Pipeline::Input::Tabular;
use Moose::Role;

use 5.014000;
use List::AllUtils qw/indexes/;
use String::Util qw/hascontent trim/;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

=head3 no_column_names

By default, B<ETL::Pipeline::Input::Tabular> assumes that the first data row 
has column names (headers) and not real data. If your data does not have column
names, set this boolean flag to B<true>.

  $etl->input( 'Excel', no_column_names => 1 );

=cut

has 'no_column_names' => (
	default => 0,
	is      => 'ro',
	isa     => 'Bool',
);


=head3 skipping

B<skipping> jumps over a certain number of records in the beginning of the
file. Report formats often contain extra headers - even before the column
names. B<skipping> ignores those and starts processing at the data.

B<skipping> accepts either an integer or code reference. An integer represents
the number of rows/records to ignore. For a code reference, the code discards
records until the subroutine returns a I<true> value.

  # Bypass the first three rows.
  $etl->input( 'Excel', skipping => 3 );
  
  # Bypass until we find something in column 'C'.
  $etl->input( 'Excel', skipping => sub { hascontent( $_->get( 'C' ) ) } );

=cut

has 'skipping' => (
	default => 0,
	is      => 'ro',
	isa     => 'CodeRef|Int',
);


# This block of code implements both "skipping" and "no_column_names".
after 'configure' => sub {
	my $self = shift @_;

	# "skipping"
	my $headers = $self->skipping;
	if (ref( $headers ) eq 'CODE') {
		do {
			$self->next_record;
		} until $self->pipeline->execute_code_ref( $headers );
		$self->_cached( 1 );
	} else { $self->next_record foreach (1 .. $headers); }

	# "no_column_names"
	$self->get_column_names unless $self->no_column_names;
};


# This attribute indicates if the next record has been cached in memory. When
# processing variable length report headers, I can't tell they end until I read
# the next line. If the next line is where your data starts, then I can't just
# throw it away. This attribute tells the code to process the current record in
# memory instead of reading one from disk.
# 
# The code automatically adjusts the record count down, so that we don't count
# this record twice.
has '_cached' => (
	default => 0,
	is      => 'rw',
	isa     => 'Bool',
	trigger => \&_trigger_cached,
);


around 'next_record' => sub {
	my ($original, $self, @arguments) = @_;

	if ($self->_cached) {
		$self->_cached( 0 );
		return 1;
	} else { return $original->( $self, @arguments ); }
};


sub _trigger_cached {
	my ($self, $new, $old) = @_;
	$self->decrement_record_number if $new;
}


=head2 Other Methods & Attributes

=head3 get_column_names

This method reads the column name row, parses it, and sets L</column_names>.
B<ETL::Pipeline::Input::TabularFile> knows nothing about the internal storage
of individual records. It relies on the implementing class for that ability.
That's where B<get_column_names> comes into play.

B<get_column_names> should call L</add_column> for each column name.

  sub get_column_names {
    my ($self) = @_;
    $self->next_record;
    # Loop through all of the fields...
      $self->add_column( $value, $field );
  }

=cut

requires 'get_column_names';


=head3 column_names

B<column_names> holds a list of the column names as read from the file. The
list is kept in file order. Duplicate names are allowed. B<column_names> is 
filled when L</get_column_names> calls the L</add_column> method. 

When L<ETL::Pipeline/mapping> calls L<ETL::Pipeline::Input/get>, this role
intercepts the call. The role translates column names or regular expressions
into actual field names. L<ETL::Pipeline::Input/get> returns a list of values
from all fields that match.

=cut

has 'column_names' => (
	default  => sub { [] },
	handles  => {
		_add_column_name    => 'push', 
		_clear_column_names => 'clear', 
		columns             => 'elements', 
		_get_column_name    => 'get',
		number_of_columns   => 'count',
	},
	init_arg => undef,
	is       => 'ro',
	isa      => 'ArrayRef[Str]',
	traits   => [qw/Array/],
);


# This private hash is used for non-numeric field names.
has '_column_mapping' => (
	default  => sub { {} },
	handles  => {
		_clear_column_mapping => 'clear',
		column_mapped         => 'exists',
		_get_field_names      => 'get', 
		_set_column_mapping   => 'set',
	},
	init_arg => undef,
	is       => 'ro',
	isa      => 'HashRef[ArrayRef[Any]]',
	traits   => [qw/Hash/],
);


around 'get' => sub {
	my ($original, $self, $field, @arguments) = @_;
	
	# Find the first match based on order fields appear in the file.
	my @matches;
	if (ref( $field ) eq 'Regexp') {
		@matches = indexes { m/$field/ } $self->columns;
	} else {
		@matches = indexes { $_ eq $field } $self->columns;
	}

	# See if this column name maps to a field. If it doesn't, the index
	# number is the real field name.
	my @real_field;
	foreach my $index (@matches) {
		my $column = $self->_get_column_name( $index );
		if ($self->column_mapped( $column )) {
			push @real_field, @{$self->_get_field_names( $column )};
		} else {
			push @real_field, $index;
		}
	}

	# Call the real "get" method with the translated field name.
	if (scalar( @real_field ) == 0) {
		if (ref( $field ) eq 'Regexp') {
			return ();
		} else {
			return $original->( $self, $field, @arguments );
		}
	} else {
		return map { $original->( $self, $_, @arguments ) } @real_field;
	}
};


=head3 add_column

L</get_column_names> calls this method once for every column name. 
B<add_column> puts the column name into L</column_names>.

L</get_column_names> passes in the column name as the first parameter and the
field name as the second. The field name is optional. 
L<ETL::Pipeline::Input/get> will use the L</column_names> index as the field 
name by default.

  # Add column names for fields 0 and 1. No field name means that "get" uses
  # the index numbers - 0 and 1.
  $self->add_column( 'First' );
  $self->add_column( 'Second' );
  
  # Add column names for fields 'A' and 'B'. Always pass the field name if
  # it's a string.
  $self->add_column( 'First', 'A' );
  $self->add_column( 'Second', 'B' );

B<Note:> B<add_column> trims leading and trailing whitespace from column names.

=cut

sub add_column {
	my $self = shift;
	my $name = trim( shift );
	
	$self->_add_column_name( $name );

	# Always return the first field with a given name. 
	if (scalar( @_ ) > 0) {
		my $field = shift;
		my $mapping = $self->_get_field_names( $name );
		if (defined $mapping) {
			push @$mapping, $field;
		} else {
			$self->_set_column_mapping( $name, [$field] );
		}
	}
}


=head3 reset_column_names

This method wipes out the existing column names. It can be used from
L</get_column_names>.

  $self->reset_column_names;

=cut

sub reset_column_names {
	my ($self) = @_;
	$self->_clear_column_mapping;
	$self->_clear_column_names;
}


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Input::File>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2016 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;

# Required by Perl to load the module.
1;
