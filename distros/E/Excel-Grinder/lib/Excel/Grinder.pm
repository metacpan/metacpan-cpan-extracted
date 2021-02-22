package Excel::Grinder;

our $VERSION = "1.0";

# time to grow up
use strict;
use warnings;
use Carp;

# this stands on the feet of giants
use Excel::Writer::XLSX;
use Spreadsheet::XLSX;

# OO out of habit
sub new {
	my ($class, $default_directory) = @_;
	
	# default the default directory to /tmp/excel_grinder
	$default_directory ||= '/tmp/excel_grinder';
	
	# make sure that directory exists
	mkdir $default_directory if !(-d $default_directory);
	
	# if it still does exist, bail out
	croak "Error: $default_directory does not exist and cannot be auto-created." if !(-d $default_directory);
	
	# become!
	my $self = bless {
		'default_directory' => $default_directory,
	}, $class;
	
	return $self;
}

# method to convert a three-level array into a nice excel file
sub write_excel {
	# required arguments are (1) the filename and (2) the data structure to turn into an XLSX file
	my ($self, %args) = @_;
	# looks like:
	#	'filename' => 'some_file.xlsx', # will be saved under /opt/majestica/tmp/DATABASE_NAME/some_file.xlsx; required
	#	'the_data' => @$three_level_arrayref, # worksheets->rows->columns; see below; required
	#	'headings_in_data' => 1, # if filled, first row of each worksheet will be captialized; optional
	#	'worksheet_names' => ['Names','of','Worksheets'], # if filled, will be the names to give the worksheets

	my ($tmp_dir, $item, $col, @bits, $workbook, $worksheet_data, $worksheet, $n, $row_array, $row_upper, $worksheet_name);

	# fail without a filename
	croak 'Error: Filename required for write_excel()' if !$args{filename};

	# the data structure must be an array of arrays of arrays
	# three levels: worksheets, rows, columns
	croak 'Error: Must send a three-level arrayref (workbook->rows->columns) to write_excel()' if !$args{the_data}[0][0][0];

	# place into default_directory unless they specified a directory

	$args{filename} = $self->{default_directory}.'/'.$args{filename} if $args{filename} !~ /\//;
	$args{filename} .= '.xlsx' if $args{filename} !~ /\.xlsx$/;

	# start our workbook
	$workbook = Excel::Writer::XLSX->new( $args{filename} );

	# Set the format for dates.
	my $date_format = $workbook->add_format( num_format => 'mm/dd/yy' );

	# start adding worksheets
	foreach $worksheet_data (@{ $args{the_data} }) {
		$worksheet_name = shift @{ $args{worksheet_names} }; # if it's there
		$worksheet_name =~ s/[^0-9a-z\-\s]//gi; # clean it up
		$worksheet = $workbook->add_worksheet($worksheet_name);
		
		# go thru each row...
		$n = 0;
		foreach $row_array (@$worksheet_data) {

			# do they want the first row to the headings?
			if ($args{headings_in_data} && $n == 0) { # uppercase the first row
				@$row_upper = map { uc($_) } @$row_array;
				$row_array = $row_upper;
			}
			
			# now each column...
			$col = 0;
			foreach $item (@$row_array) {
				# dates are no funzies
				if ($item =~ /^(\d{4})-(\d{2})-(\d{2})$/) { # special routine for dates
					$worksheet->write_date_time( $n, $col++, $1.'-'.$2.'-'.$3.'T', $date_format );
				} else {
					 $worksheet->write( $n, $col++, $item );
				}

			}
			$n++;
		}
	}

	# that's not so hard, now is it?
	return $args{filename};
}

# method to import an excel file into a nice three-level array
sub read_excel {
	# require argument is the filename or  full path to the excel xlsx file
	# if it's just a filename, look in the default directory
	my ($self,$filename) = @_;

	$filename = $self->{default_directory}.'/'.$filename if $filename !~ /\//;	
	$filename .= '.xlsx' if $filename !~ /\.xlsx$/;

	# gotta exist, after all that
	croak 'Error: Must send a valid full file path to an XLSX file to read_excel()' if !(-e "$filename");
	
	my ($excel, $sheet_num, $sheet, $row_num, $row, @the_data, $cell, $col);

	# again, stand on the shoulders of giants
	$excel = Spreadsheet::XLSX->new($filename);

	# read it in, sheet by sheet
	$sheet_num = 0;
	foreach $sheet (@{$excel->{Worksheet}}) {

		# set the max = 0 if there is one or none rows
		$sheet->{MaxRow} ||= $sheet->{MinRow};

		# same for the columns
		$sheet->{MaxCol} ||= $sheet->{MinCol};

		# cycle through each row
		$row_num = 0;
		foreach $row ($sheet->{MinRow} .. $sheet->{MaxRow}) {
			# go through each available column
			foreach $col ($sheet->{MinCol} ..  $sheet->{MaxCol}) {

                # get ahold of the actual cell object
				$cell = $sheet->{Cells}[$row][$col];
				
				# next if !$cell; # skip if blank

				# add it to our nice array
				push (@{ $the_data[$sheet_num][$row] }, $cell->{Val} );
			}
			# advance
			$row_num++;
        }
		$sheet_num++;
	}

	# send it back
	return \@the_data;
}

1;

__END__

=head1 NAME

Excel::Grinder - Import/export plain Excel (XLSX) files as simply as possible.

=head1 DESCRIPTION / PURPOSE

This module should help you read/write XLSX spreadsheets to/from Perl arrays 
as simply as possible. The use cases are (1) when you need to export data from 
your database/application for non-programmers to enjoy in their beloved Excel 
and (2) when you need to allow for batch import/update operations via 
user-provided Excel.

There are so many awesome things you can do with Excel (formatting, formulas, 
pivot tables, etc.) but this module does none of that.  This is for the basic 
read-it-in and write-it-out -- which might just fit the bill.

This module will read an Excel (XLSX) file into a three-level arrayref.  The first
level is the worksheets, second level is the rows, and third level is the cells, such that:

	$$my_data[4][2][10] --> Worksheet 5, Row 3, Column 11 (aka as Column K)
	
Form a three-level arrayref to represent worksheets/rows/cells in this way, and you can create
a plain Excel XLSX file.  No formatting or formulas.  Ready for Tableau or just to confuse
your favorite front-line manager.

I put this together because I was offended at how difficult it is just to create an Excel
file in certain non-Perl environments, and since Excel is just a part of life for so many of us,
it really should be dead-simple.

To pursue additional Excel features, please see the excellent L<Excel::Writer::XLSX> and 
L<Spreadsheet::XLSX> modules, of which this module is just a simple abstraction.

=head1 SYNOPSIS

	# create the object to read/write excel files
	my $xlsx = Excel::Grinder->new('/opt/data/excel_files'); 
	# the directory can be anywhere that is writable; leave blank for /tmp/excel_grinder

	# to create a two-worksheet Excel workbook at /opt/data/excel_files/our_family.xlsx
	my $full_file_path = $xlsx->write_excel(
		'filename' => 'our_family.xlsx',
		'headings_in_data' => 1,
		'worksheet_names' => ['Dogs','People'],
		'the_data' => [
			[
				['Name','Main Trait','Age Type'],
				['Ginger','Wonderful','Old'],
				['Pepper','Loving','Passed'],
				['Polly','Fun','Young'],
				['Daisy','Crazy','Puppy']
			],
			[
				['Name','Main Trait','Age Type'],
				['Melanie','Smart','Oldish'],
				['Lorelei','Fun','Young'],
				['Eric','Fat','Old']
			]
		],
	);	
	
	# if you prebuilt had that three-level array in $our_family_data:
	$full_file_path = $xlsx->write_excel(
		'filename' => 'our_family.xlsx',
		'headings_in_data' => 1,
		'worksheet_names' => ['Dogs','People'],	
		'the_data' => $our_family_data
	);
	
	# to read that spreadsheet back into an three-level arrayref that is just like
	# what we fed in to write_excel() above:	
	my $family_data = $xlsx->read_excel('our_family.xlsx');

	# Now you can modify or add to $family_data, and overwrite our_family.xlsx 
	# or create another XLSX file.

=head1 METHODS

=head2 new()

Creates a new object to use this module.  Accepts a 'default directory' path for where
to save / load the Excel files:

	$xlsx = Excel::Grinder->new('/home/ginger/excel_files');
	
If you leave out that directory argument, the default is /tmp/excel_grinder .

=head2 write_excel()

Take a properly-formed three-level array and create an XLSX file.  The simplest
way to invoke.

	$full_file_path = $xlsx->write_excel(
		'filename' => 'some_filename.xlsx',
		'the_data' => $some_data
	);
	
The return value is the full location (file path) of the new file.

'Properly-formed' means the data itself is really at the third level,
while the first two just organize it into worksheets and rows:

	$websites = [
		[
			[ 'Facebook','https://www.facebook.com', ],
			[ 'LinkedIn','https://www.linkedin.com', ],
			[ 'Google','https://www.google.com', ],
		],
		[
			[ 'CPAN','https://metacpan.org/', ],
			[ 'Perl.Org','https://www.perl.org/', ]
		],
	];
	
This represents an Excel workbook with two worksheets.  The first one has three two-column rows,
and the second one has two two-column rows.  Often, a structure like this would be defined 
during a loop of some kind, or perhaps feed from the results of DBI's fetchall_arrayref().
Yes, you might just have one worksheet, but you would still prepare a three-level arrayref,
with just one element at the top.  Sorry.

The 'headings_in_data' arg tells use to make each worksheet's first row all caps to 
indicate those are the headings.  The 'worksheet_names' argument is the arrayref to 
the names to put on the nice tabs for the worksheets.  Both 'worksheet_names' and 
'headings_in_data' are optional.

=head2 read_excel()

This does the exact opposite of write_excel() in that it reads in an XLSX
file and returns the arrayref in the exact same format as what write_excel()
receives.  All it needs is the absolute filepath for an XLSX file:

	$the_data = $xlsx->read_excel('/opt/data/excel_files/DATABASE_NAME/ginger.xlsx');
	# or you can just provide the filename, so long as it is in the default
	# directory path provided in new()

@$the_data will look like the structure in the examples above.  Try it out ;)

=head1 SEE ALSO

L<Excel::Writer::XLSX> 
 
L<Spreadsheet::XLSX>

=head1 AUTHOR

Eric Chernoff <eric@weaverstreet.net>

Please send me a note with any bugs or suggestions.

=head1 LICENSE

MIT License

Copyright (c) 2021 Eric Chernoff

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
