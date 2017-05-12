=pod

=head1 NAME

ETL::Pipeline::Input::Excel - Input source for Microsoft Excel spreadsheets

=head1 SYNOPSIS

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['Excel', matching => qr/\.xlsx$/i],
    mapping => {First => 'A', Second => qr/ID\s*Num/i},
    output  => ['UnitTest']
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Input::Excel> defines an input source for reading MS Excel
spreadsheets. It uses L<Spreadsheet::XLSX> or L<Spreadsheet::ParseExcel>, 
depending on the file type (XLSX or XLS).

=cut

use 5.014000;
use warnings;

package ETL::Pipeline::Input::Excel;
use Moose;

use Carp;
use List::AllUtils qw/first/;
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseExcel::Utility qw/int2col/;
use Spreadsheet::XLSX;
use String::Util qw/hascontent/;


our $VERSION = '2.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

B<ETL::Pipeline::Input::DelimitedText> implements L<ETL::Pipeline::Input::File>
and L<ETL::Pipeline::Input::TabularFile>. It supports all of the attributes
from these roles.

=head3 return_blank_rows

L<Spreadsheet::XLSX> or L<Spreadsheet::ParseExcel> can't identify merged rows.
Merged rows simply appear as blanks. So by default, 
B<ETL::Pipeline::Input::Excel> skips over blank rows. Merged rows look like one
record. When counting headers, do not count empty rows. 

This boolean attribute overrides the default behaviour. 
B<ETL::Pipeline::Input::Excel> returns blank rows as an empty record.

=cut

has 'return_blank_rows' => (
	default => 0,
	is      => 'rw',	# Allow callbacks to change this flag!
	isa     => 'Bool',
);


=head3 worksheet

B<worksheet> reads data from a specific worksheet. By default, 
B<ETL::Pipeline::Input::Excel> uses the first worksheet.

B<worksheet> accepts a string or regular expression. As a string, B<worksheet>
looks for an exact match. As a regular expression, B<worksheet> finds the first
worksheet whose name matches the regular expression. Note that B<worksheet>
stops looking once it finds the first mach.

B<ETL::Pipeline::Input::Excel> throws an error if it cannot find a worksheet
with a matching name.

=cut

has 'worksheet' => (
	is  => 'ro',
	isa => 'Maybe[RegexpRef|Str]',
);


=head3 password

B<password> works with encrypted files. B<ETL::Pipeline::Input::Excel> decrypts
the file automatically.

B<Warning:> B<password> only works with Excel 2003 file (XLS). Encrypted XLSX 
files always fail. L<Spreadsheet::XLSX> does not support encryption.

=cut

has 'password' => (
	is  => 'ro',
	isa => 'Maybe[Str]',
);


=head2 Called from L<ETL::Pipeline/process>

=head3 get

B<get> retrieves one field from the current record. B<get> accepts one
parameter. That parameter can be an index number, a column name, or a regular
expression to match against column names.

  $etl->get( 0 );
  $etl->get( 'A' );
  $etl->get( 'First' );
  $etl->get( qr/\bfirst\b/i );

=cut

sub get {
	my ($self, $column) = @_;

	return undef unless $column =~ m/^\d+$/;

	my $row  = $self->row;
	my $cell = $self->tab->{Cells}->[$row][$column];
	return defined( $cell ) ? $cell->value : undef;
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

	# If the last read grabbed the last row, then we've reached the end. This
	# read will fail.
	my $row      = $self->row;
	my $last_row = $self->tab->{MaxRow};
	return 0 if $row == $last_row;

	# We're still in the data, so retrieve this row.
	my $empty = 1;
	my $cells = $self->tab->{Cells};

	# Skip blank rows, but don't loop forever.
	while ($row <= $last_row && $empty) {
		$row++;
		if ($self->return_blank_rows) {
			$empty = 0;
		} else {
			$empty = 1;
			foreach my $column ($self->tab->{MinCol} .. $self->tab->{MaxCol}) {
				if (hascontent( $cells->[$row][$column]->value )) {
					$empty = 0;
					last;
				}
			}
		}
	}
	$self->row( $row );

	# If it's an emtpy row, then we reached the end of the data.
	return ($empty ? 0 : 1);
}


=head3 get_column_names

B<get_column_names> reads the field names from the first row in the file.
L</get> can match field names using regular expressions.

=cut

sub get_column_names {
	my ($self) = @_;
	
	$self->next_record;
	$self->add_column( $self->get( $_ ), $_ ) 
		foreach ($self->tab->{MinCol} .. $self->tab->{MaxCol});
}


=head3 configure

B<configure> opens the MS Excel spread sheet for reading. It creates the 
correct worksheet object for XLS versus XLSX. XLS and XLSX files are different 
formats. B<ETL::Pipeline::Input::Excel> uses the correct module for this 
specific file. 

Both Excel parsers use coulmn numbers, starting with zero. B<configure>
automatically creates aliases for the column letters.

=cut

sub configure {
	my ($self) = @_;

	# Create the correct worksheet objects based on the file format.
	my $path = $self->file->stringify;
	my $workbook;
	
	if ($path =~ m/\.xls$/i) {
		my $excel = Spreadsheet::ParseExcel->new( Password => $self->password );
		$workbook = $excel->parse( $path );
		croak "Unable to open the Excel file $path" unless defined $workbook;
	} else {
		$workbook = Spreadsheet::XLSX->new( $path );
		croak "Unable to open the Excel file $path" unless defined $workbook;
	}

	# Find the worksheet with data...
	my $name = $self->worksheet;
	my $worksheet;
	if (hascontent( $name )) {
		if (ref( $name ) eq 'Regexp') {
			$worksheet = first { $_->get_name() =~ m/$name/ } $workbook->worksheets();
		} else { 
			$worksheet = $workbook->worksheet( $name );
		}
		croak "No workseets match '$name'" unless defined $worksheet;
	} else {
		$worksheet = $workbook->worksheet( 0 );
		croak "'$path' has no worksheets" unless defined $worksheet;
	}
	$self->tab( $worksheet );

	# Convert the column numbers into their letter designations. Do this here
	# instead of in getl_column_names. The letters apply to every spread sheet
	# - even if no_column_names = 1, which bypasses get_column_names.
	$self->add_column( int2col( $_ ), $_ ) 
		foreach ($worksheet->{MinCol} .. $worksheet->{MaxCol});

	# Start on the first row as defined by the spread sheet.
	$self->row( $worksheet->{MinRow} - 1 );
}


=head3 finish

B<finish> closes the file.

=cut

sub finish {}


=head2 Other Methods & Attributes

=head3 row

B<row> is the next row in the spreadsheet for reading. Because 
B<ETL::Pipeline::Input::Excel> skips blank rows, the L</record_number> may not
match the row number. 

=cut

has 'row' => (
	is  => 'rw',
	isa => 'Int',
);


=head3 tab

B<tab> holds the current worksheet object. The Excel parsers return an object 
for the tab (worksheet) with the data. It is set by L</find_worksheet>.

=cut

has 'tab' => (
	is  => 'rw',
	isa => 'Maybe[Spreadsheet::ParseExcel::Worksheet]',
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
