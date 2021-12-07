=pod

=head1 NAME

ETL::Pipeline::Input::Excel - Input source for Microsoft Excel spreadsheets

=head1 SYNOPSIS

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['Excel', iname => qr/\.xlsx$/i],
    mapping => {First => 'A', Second => qr/ID\s*Num/i},
    output  => ['UnitTest']
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Input::Excel> defines an input source for reading MS Excel
spreadsheets. It uses L<Spreadsheet::XLSX> or L<Spreadsheet::ParseExcel>,
depending on the file type (XLSX or XLS).

=cut

package ETL::Pipeline::Input::Excel;

use 5.014000;
use warnings;

use Carp;
use List::AllUtils qw/first none/;
use Moose;
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseExcel::Utility qw/int2col/;
use Spreadsheet::XLSX;
use String::Util qw/hascontent/;


our $VERSION = '3.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

B<ETL::Pipeline::Input::Excel> implements the L<ETL::Pipeline::Input::File>
and L<ETL::Pipeline::Input::File::Table> roles. It supports all of the
attributes from these roles.

=head3 worksheet

Optional. B<worksheet> reads data from a specific worksheet. By default,
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

Optional. B<password> works with encrypted files. B<ETL::Pipeline::Input::Excel>
decrypts the file automatically.

B<Warning:> B<password> only works with Excel 2003 file (XLS). Encrypted XLSX
files always fail. L<Spreadsheet::XLSX> does not support encryption.

=cut

has 'password' => (
	is  => 'ro',
	isa => 'Maybe[Str]',
);


=head3 skipping

Optional. If you use a code reference for B<skipping>, this input source sends a
hash reference. You can access the columns by number or letter.

If you pass an integer, the input source completely skips over that many lines.

=head2 Methods

=head3 run

This is the main loop. It opens the file, reads records, and closes it when
done. This is the place to look if there are problems.

L<ETL::Pipeline> automatically calls this method.

=cut

sub run {
	my ($self, $etl) = @_;

	#----------------------------------------------------------------------
	# Open the file.

	# Create the correct workbook object based on the file format.
	my $path = $self->path;
	my $workbook;

	if ("$path" =~ m/\.xls$/i) {
		my $excel = Spreadsheet::ParseExcel->new( Password => $self->password );
		$workbook = $excel->parse( "$path" );
		croak "Unable to open the Excel file '$path'" unless defined $workbook;
	} else {
		$workbook = Spreadsheet::XLSX->new( "$path" );
		croak "Unable to open the Excel file '$path'" unless defined $workbook;
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
		croak "No worksheets match '$name'" unless defined $worksheet;
	} else {
		$worksheet = $workbook->worksheet( 0 );
		croak "'$path' has no worksheets" unless defined $worksheet;
	}

	# Convert the column numbers into their letter designations.
	my %names;
	$names{int2col( $_ )} = $_ foreach ($worksheet->{MinCol} .. $worksheet->{MaxCol});
	$etl->aliases( \%names );

	#----------------------------------------------------------------------
	# Read the records.
	my $cells = $worksheet->{Cells};
	my $start = $worksheet->{MinRow};

	# Skip over report headers. These are not data. They are extra rows put
	# there for report formats. The data starts after these rows.
	my $skip = $self->skipping;
	if (ref( $skip ) eq 'CODE') {
		while ($start <= $worksheet->{MaxRow}) {
			my %record;
			foreach my $column ($worksheet->{MinCol} .. $worksheet->{MaxCol}) {
				$record{$column} = $cells->[$start][$column]->value;
			}
			foreach my $alias ($etl->aliases) {
				while (my ($name, $column) = each %$alias) {
					$record{$name} = $record{$column} if
						exists( $record{$column} )
						&& !exists( $record{$name} )
					;
				}
			}
			last if !$skip->( \%record );
			$start++;
		}
	} elsif ($skip > 0) {
		$start += $skip;
	}

	# Load field names.
	unless ($self->no_column_names) {
		my @names;
		push( @names, {$cells->[$start][$_]->value => $_} )
			foreach ($worksheet->{MinCol} .. $worksheet->{MaxCol});
		$etl->aliases( @names );

		$start++;
	}

	# Load the data.
	my $source = $self->source;
	foreach my $row ($start .. $worksheet->{MaxRow}) {
		$self->source( sprintf( '%s at row %d', $source, $row + 1 ) );

		my $record = [];
		push( @$record, $cells->[$row][$_]->value )
			foreach ($worksheet->{MinCol} .. $worksheet->{MaxCol});
		$etl->record( $record );
	}
}


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Input::File>,
L<ETL::Pipeline::Input::File::Table>

=cut

with 'ETL::Pipeline::Input';
with 'ETL::Pipeline::Input::File';
with 'ETL::Pipeline::Input::File::Table';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2021 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
