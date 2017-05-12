=pod

=head1 NAME

ETL::Pipeline::Input::DelimitedText - Input source for CSV, tab, or pipe
delimited files

=head1 SYNOPSIS

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['DelimitedText', matching => qr/\.csv$/i],
    mapping => {First => 'Header1', Second => 'Header2'},
    output  => ['UnitTest']
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Input::DelimitedText> defines an input source for reading 
CSV (comma seperated variable), tab delimited, or pipe delimited files. It
uses L<Text::CSV> for parsing.

=cut

package ETL::Pipeline::Input::DelimitedText;
use Moose;

use 5.014000;
use warnings;

use Carp;
use Text::CSV;


our $VERSION = '2.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

B<ETL::Pipeline::Input::DelimitedText> implements L<ETL::Pipeline::Input::File>
and L<ETL::Pipeline::Input::TabularFile>. It supports all of the attributes
from these roles.

In addition, B<ETL::Pipeline::Input::DelimitedText> makes available all of the
options for L<Text::CSV>. See L<Text::CSV> for a list.

  # Pipe delimited, allowing embedded new lines.
  $etl->input( 'DelimitedText', 
    matching => qr/\.dat$/i, 
    sep_char => '|', 
    binary => 1
  );

=cut

sub BUILD {
	my $self= shift;
	my $arguments = shift;

	my %options;
	while (my ($key, $value) = each %$arguments) {
		$options{$key} = $value unless $self->meta->has_attribute( $key );
	}

	$self->csv( Text::CSV->new( \%options ) );
}


=head2 Called from L<ETL::Pipeline/process>

=head3 get

B<get> retrieves one field from the current record. B<get> accepts one
parameter. That parameter can be an index number, a column name, or a regular
expression to match against column names.

  $etl->get( 0 );
  $etl->get( 'First' );
  $etl->get( qr/\bfirst\b/i );

=cut

sub get {
	my ($self, $index) = @_;
	return undef unless $index =~ m/^\d+$/;
	return $self->_get_value( $index );
}


=head3 next_record

Read one record from the file for processing. B<next_record> returns a boolean.
I<True> means success. I<False> means it reached the end of the file.

  while ($input->next_record) {
    ...
  }

=cut

sub next_record {
	my ($self) = @_;

	my $fields = $self->csv->getline( $self->handle );
	if (defined $fields) {
		$self->record( $fields );
		return 1;
	} else {
		return 0 if $self->csv->eof;
		my ($code, $message, $position) = $self->csv->error_diag;
		croak "Error $code: $message at character $position";
	}
}


=head3 get_column_names

B<get_column_names> reads the field names from the first row in the file.
L</get> can match field names using regular expressions.

=cut

sub get_column_names {
	my ($self) = @_;
	
	$self->next_record;
	$self->add_column( $_ ) foreach ($self->fields);
}


=head3 configure

B<configure> opens the file for reading. It takes care of loading the column
names, if your file has them.

=cut

sub configure {
	my ($self) = @_;

	$self->handle( $self->file->openr() );
	die sprintf( 'Unable to open "%s" for reading', $self->file->stringify )
		unless defined $self->handle;
}


=head3 finish

B<finish> closes the file.

=cut

sub finish { close shift->handle; }


=head2 Other Methods & Attributes

=head3 record

B<ETL::Pipeline::Input::DelimitedText> stores each record as a list of fields.
The field name corresponds with the file order of the field, starting at zero.
This attribute holds the current record.

=head3 fields

Returns a list of fields from the current record. It dereferences L</record>.

=head3 number_of_fields

This method returns the number of fields in the current record.

=cut

has 'record' => (
	handles => {
		fields           => 'elements', 
		_get_value       => 'get', 
		number_of_fields => 'count',
	},
	is     => 'rw',
	isa    => 'ArrayRef[Any]',
	traits => [qw/Array/],
);


=head3 csv

B<csv> holds a L<Text::CSV> object for reading the file. You can set options
for L<Text::CSV> in the L<ETL::Pipeline/input> command. 

=cut

has 'csv' => (
	is  => 'rw',
	isa => 'Text::CSV',
);


=head3 handle

The Perl file handle for reading data. L<Text::CSV> operates on a handle. 
L</next_record> needs the handle.

=cut

has 'handle' => (
	is  => 'rw',
	isa => 'Maybe[FileHandle]',
);


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Input::File>,
L<ETL::Pipeline::Input::Tabular>

=cut

with 'ETL::Pipeline::Input::File';
with 'ETL::Pipeline::Input::Tabular';
with 'ETL::Pipeline::Input';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2016 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
