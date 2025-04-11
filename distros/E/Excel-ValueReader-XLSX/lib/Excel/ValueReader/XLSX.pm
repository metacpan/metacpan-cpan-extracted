package Excel::ValueReader::XLSX;
use 5.12.1;
use utf8;
use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints qw/union/;
use Module::Load                 qw/load/;
use Date::Calc                   qw/Add_Delta_Days/;
use POSIX                        qw/strftime modf/;
use Carp                         qw/croak/;
use Iterator::Simple             qw/iter/;

#======================================================================
# GLOBALS
#======================================================================

our $VERSION = '1.16';
our %A1_to_num_memoized;

#======================================================================
# TYPES AND ATTRIBUTES
#======================================================================

# TYPES
my $XlsxSource = union([qw/Str FileHandle/]);

# PUBLIC ATTRIBUTES
has 'xlsx'            => (is => 'ro', isa => $XlsxSource,      required => 1);      # path of xlsx file
has 'using'           => (is => 'ro', isa => 'Str',            default => 'Regex'); # name of backend class
has 'date_format'     => (is => 'ro', isa => 'Str',            default => '%d.%m.%Y');
has 'time_format'     => (is => 'ro', isa => 'Str',            default => '%H:%M:%S');
has 'datetime_format' => (is => 'ro', isa => 'Str',            builder => '_datetime_format', lazy => 1);
has 'date_formatter'  => (is => 'ro', isa => 'Maybe[CodeRef]', builder => '_date_formatter',  lazy => 1);

# ATTRIBUTES USED INTERNALLY, NOT DOCUMENTED
has 'backend'         => (is => 'ro', isa => 'Object',         builder => '_backend',         lazy => 1,
                          init_arg => undef, handles => [qw/base_year sheets active_sheet table_info/]);

#======================================================================
# BUILDING
#======================================================================

# syntactic sugar for supporting ->new($path) instead of ->new(xlsx => $path)
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  unshift @_, 'xlsx' if scalar(@_) % 2 and $XlsxSource->check($_[0]);

  $class->$orig(@_);
};


#======================================================================
# ATTRIBUTE CONSTRUCTORS
#======================================================================

sub _backend {
  my $self = shift;

  my $backend_class = ref($self) . '::Backend::' . $self->using;
  load $backend_class;

  return $backend_class->new(frontend => $self);
}

sub _datetime_format {
  my ($self) = @_;
  return $self->date_format . ' ' . $self->time_format;
}

sub _date_formatter {
  my ($self) = @_;

  # local copies of the various formats so that we can build a closure
  my @formats = (undef,                     # 0 -- error
                 $self->date_format,        # 1 -- just a date
                 $self->time_format,        # 2 -- just a time
                 $self->datetime_format);   # 3 -- date and time

  my $strftime_formatter = sub {
    my ($xl_date_format, $y, $m, $d, $h, $min, $s, $ms) = @_;

    # choose the proper format for strftime
    my $ix = 0; # index into the @formats array
    $ix += 1 if $xl_date_format =~ /[dy]/; # the Excel format contains a date portion
    $ix += 2 if $xl_date_format =~ /[hs]/; # the Excel format contains a time portion
    my $strftime_format = $formats[$ix]
      or die "cell with unexpected Excel date format : $xl_date_format";

    # formatting through strftime
    my $formatted_date = strftime($strftime_format, $s, $min, $h, $d, $m-1, $y-1900);

    return $formatted_date;
  };

  return $strftime_formatter;
}


#======================================================================
# GENERAL METHODS
#======================================================================


sub sheet_names {
  my ($self) = @_;

  my $sheets = $self->sheets; # hashref of shape {$name => $sheet_position}

  my @sorted_names = sort {$sheets->{$a} <=> $sheets->{$b}} keys %$sheets;
  return @sorted_names;
}


sub values  { my ($self, $sheet) = @_; $self->backend->_values($sheet, 0)}
sub ivalues { my ($self, $sheet) = @_; $self->backend->_values($sheet, 1)}

sub formatted_date {
  my ($self, $val, $date_format, $date_formatter) = @_;

  # separate date (integer part) from time (fractional part)
  my ($time, $n_days) = modf($val);

  # Convert $n_days into a date in Date::Calc format (year, month, day).
  # The algorithm is quite odd because in the 1900 system, 01.01.1900 == 0 while
  # in the 1904 system, 01.01.1904 == 1; furthermore, in the 1900 system,
  # Excel treats 1900 as a leap year.
  my $base_year  = $self->base_year;
  if ($base_year == 1900) {
    my $is_after_february_1900 = $n_days > 60;
    $n_days -= $is_after_february_1900 ? 2 : 1;
  }
  my @d = Add_Delta_Days($base_year, 1, 1, $n_days);

  # decode the fractional part (the time) into hours, minutes, seconds, milliseconds
  my @t;
  foreach my $subdivision (24, 60, 60, 1000) {
    $time                    *= $subdivision;
    ($time, my $time_portion) = modf($time);
    push @t, $time_portion;
  }

  # dirty hack to deal with float imprecisions : if 999 millisecs, round to the next second
  my ($h, $m, $s, $ms) = @t;
  if ($ms == 999) {
    $s += 1, $ms = 0;
    if ($s == 60) {
      $m += 1, $s = 0;
      if ($m == 60) {
        $h += 1, $m = 0;
      }
    }
  }
  # NOTE : because of this hack, theoretically we could end up with a value
  # like 01.01.2000 24:00:00, semantically equal to 02.01.2000 00:00:00 but different
  # in its rendering.

  # call the date_formatter subroutine
  $date_formatter //= $self->date_formatter
    or die ref($self) . " has no date_formatter subroutine";
  my $formatted_date = $date_formatter->($date_format, @d, $h, $m, $s, $ms);

  return $formatted_date;
}

#======================================================================
# METHODS FOR PARSING EXCEL TABLES
#======================================================================


sub table_names {
  my ($self) = @_;

  my $table_info = $self->table_info;

  # sort on table id (field [1] in table_info arrayrefs)
  my @table_names = sort {$table_info->{$a}{id} <=> $table_info->{$b}{id}} keys %$table_info;

  return @table_names;
}

sub table  {shift->_table(0, @_);} # 0 = does not want an iterator, just a regular arrayref
sub itable {shift->_table(1, @_);} # 1 = does want an iterator

my %valid_table_arg = map {$_ => 1} qw/name sheet ref columns no_headers with_totals want_records/;
sub _table {
  my $self          = shift;
  my $want_iterator = shift;

  # syntactic sugar : ->table('foo') is treated as ->table(name => 'foo')
  unshift @_, 'name' if scalar(@_) % 2;
  my %args = @_;

  # check for invalid args
  my @invalid_args = grep {!$valid_table_arg{$_}} keys %args;
  croak "invalid table args: ", join(", ", @invalid_args) if @invalid_args;

  # defaults
  $args{want_records} //= 1;

  # if called with a table name, derive positional args from the internal workbook info
  if (my $table_name = delete $args{name}) {
    my $table_info = $self->table_info->{$table_name}
      or croak sprintf "Excel file '%s' contains no table named '%s'", $self->xlsx, $table_name;
    $args{$_} //= $table_info->{$_} for keys %$table_info;
  }

  # get values from the sheet
  my ($sheet_ref, $vals_or_it) = $want_iterator ? $self->ivalues($args{sheet})
                                                : $self->values($args{sheet});

  # table boundaries 
  my ($scol1, $srow1, $scol2, $srow2) = $self->range_from_ref($sheet_ref);
  my ($tcol1, $trow1, $tcol2, $trow2) = $self->range_from_ref($args{ref});
  my $skip_initial_rows               = $trow1 - $srow1;
  my $keep_rows                       = $trow2 - $trow1 + 1;
  my $skip_initial_cols               = $tcol1 - $scol1;
  my $keep_cols                       = $tcol2 - $tcol1 + 1;

  # if a totals row is present, skip it, unless the 'with_totals' arg is present
  $keep_rows -=1 if $args{has_totals} and !$args{with_totals};

  # skip initial rows if the table does not start at top row
  if ($skip_initial_rows) {
    if ($want_iterator) {$vals_or_it->() while $skip_initial_rows-- > 0;}
    else                {splice @$vals_or_it, 0, $skip_initial_rows}
  }

  # read headers from first row -- even if this may be redundant with the 'columns' list declared in the table description
  my $headers;
  unless ($args{no_headers}) {
    $keep_rows--; 
    $headers = $want_iterator ? $vals_or_it->() : shift @$vals_or_it;
    splice @$headers, 0, $skip_initial_cols if $skip_initial_cols;
    splice @$headers, $keep_cols;
  }
  $args{columns}      //= $headers;
  croak "table contains undefined columns" if grep {!defined $_} @{$args{columns}};

  # dual closure : can be used as an iterator or can compute all values in one call
  my @rows;
  my $get_values = sub {
    while (1) {
      $keep_rows--
        and my $vals = $want_iterator ? $vals_or_it->() : shift @$vals_or_it
        or  return;                                                           # no more records -- end of iterator
      splice @$vals, 0, $skip_initial_cols if $skip_initial_cols;
      splice @$vals, $keep_cols;
      my $row = $args{want_records} ? do {my %r; @r{@{$args{columns}}} = @$vals; \%r}
                                    : $vals;
      if ($want_iterator) {return $row}                                       # current iteration successful
      else                {push @rows, $row};
    }
  };

  # return either an iterator or the accumulated table records
  return ($args{columns}, $want_iterator ? iter($get_values)
                                         : do {$get_values->(); \@rows});
}


sub A1_to_num { # convert Excel A1 reference format to a number
  my ($self, $A1) = @_;
  my $num = 0;
  foreach my $digit (unpack "C*", $A1) {
    $num = $num*26 + $digit-64;
  }

  return $num;
}


sub range_from_ref { # convert a range reference like 'C9:E21' into ($col1, $row1, $col2, $row2)
  my ($self, $range) = @_;

  $range =~ /^([A-Z]+)(\d+)                       # mandatory 1st col and row
              (?:                                  # .. optionally followed by
                 :                                 # colon
                 ([A-Z]+)(\d+)                     # and 2nd col and row
               )?
              $/x
     or croak "->range_from_ref($range) : invalid ref";

  my @range        = ($A1_to_num_memoized{$1} //= $self->A1_to_num($1), $2); # col, row of topleft cell
  push @range, ($3 ? ($A1_to_num_memoized{$3} //= $self->A1_to_num($3), $4)  # col, row of bottomright cell, or ..
                   : @range);                                                # .. copy of topleft cell
  return @range;
}






1;


__END__

=head1 NAME


Excel::ValueReader::XLSX - extracting values from Excel workbooks in XLSX format, fast

=head1 SYNOPSIS

  my $reader = Excel::ValueReader::XLSX->new(xlsx => $filename_or_handle);
  # .. or with syntactic sugar :
  my $reader = Excel::ValueReader::XLSX->new($filename_or_handle);
  # .. or with LibXML backend :
  my $reader = Excel::ValueReader::XLSX->new(xlsx => $filename_or_handle,
                                             using => 'LibXML');
  
  foreach my $sheet_name ($reader->sheet_names) {
     my $grid = $reader->values($sheet_name);
     my $n_rows = @$grid;
     print "sheet $sheet_name has $n_rows rows; ",
           "first cell contains : ", $grid->[0][0];
  }
  
  foreach my $table_name ($reader->table_names) {
     my ($columns, $records) = $reader->table($table_name);
     my $n_records           = @$records;
     my $n_columns           = @$columns;
     print "table $table_name has $n_records records and $n_columns columns; ",
           "column 'foo' in first row contains : ", $records->[0]{foo};
  }
  
  my $first_grid = $reader->values(1); # the arg can be a sheet index instead of a sheet name
  
  # iterator version of ->values()
  my $iterator = $reader->ivalues($sheet_name);
  while (my $row = $iterator->()) { process_row($row) }

  # iterator version of ->table()
  my ($columns, $iterator) = $reader->itable($table_name);
  while (my $record = $iterator->()) { process_record($record) }

=head1 DESCRIPTION

=head2 Purpose

This module reads the contents of an Excel file in XLSX format.
Unlike other modules like L<Spreadsheet::ParseXLSX> or L<Data::XLSX::Parser>, 
this module has no support for reading formulas, formats or other Excel internal
information; all you get are plain values -- but you get them much faster ! 

Besides, this API has some features not found in concurrent parsers :

=over

=item *

has support for parsing Excel tables

=item *

iterator methods for getting one row at a time from a worksheet or from a table -- very useful for sparing
memory when dealing with large Excel files.

=back


=head2 Backends

Two different backends may be used for extracting values :

=over

=item Regex

using regular expressions to parse the XML content.

=item LibXML

using L<XML::LibXML::Reader> to parse the XML content.
It is probably safer but two to three times slower than the Regex backend
(but still much faster than L<Spreadsheet::ParseXLSX>).

=back

The default is the C<Regex> backend.

=head2 Sheet numbering

Although worksheets are usually accessed by name, they may also
be accessed by numerical indices, I<starting at value 1>.
Some other Perl parsing modules use a different convention, where the first sheet has index 0.
Here index 1 was chosen to be consistent with the common API for "collections" in
Microsoft Office object model.


=head1 NOTE ON ITERATORS

Methods L</ivalues> and L</itable> return I<iterators>.
Each call to the iterator produces a new data row from the Excel content, until reaching
the end of data where the iterator returns C<undef>. Following the L<Iterator::Simple> protocol,
iterators support three different but semantically equivalent syntaxes :

  while (my $row = $iterator->())   { process($row) }
  
  while (my $row = $iterator->next) { process($row) }
  
  while (<$iterator>)               { process($_) }

Working with iterators is especially interesting when dealing with large Excel files, because
rows can be processed one at a time instead of being loaded all at once in memory. For example
a typical pattern for loading the Excel content into a database would be :

  my $iter = $valuereader->ivalues('MySheet');
  my $sth  = $dbh->prepare("INSERT INTO MYTABLE(col1, col2, col3) VALUES (?, ?, ?)");
  while (my $row = $iter->()) {
    $sth->execute(@$row);
  }
  
As another example, suppose a large population table, from which we want to produce a list of
list of minor girls. This can be done with a combination of iterator operations : 

  use Iterator::Simple       qw/igrep imap/;
  use Iterator::Simple::Util qw/ireduce/;
  my $minor_girls = ireduce {"$a, $b"}                              # successive results joined with ", "
                    imap    {"$_->{firstname} $_->{lastname}"}      # produce a flat string from an input record with first/last name
                    igrep   {$_->{gender} eq 'F' && $_->{age} < 18} # filter input records
                            $valuereader->itable('Population');     # source iterator

=head1 METHODS

=head2 new

  my $reader = Excel::ValueReader::XLSX->new(xlsx  => $filename_or_handle, %options);
  # .. or with syntactic sugar :
  my $reader = Excel::ValueReader::XLSX->new($filename_or_handle, %options);

The C<xlsx> argument is mandatory and points to the C<.xlsx> file to be parsed,
or to an open filehandle.

Options are :

=over

=item C<using>

The backend to be used for parsing; default is 'Regex'.

=item C<date_format>, C<time_format>, C<datetime_format>, C<date_formatter>

Parameters for formatting date and time values; these are described in the L</DATE AND TIME FORMATS> section below.

=back



=head2 sheet_names

  my @sheets = $reader->sheet_names;

Returns the list of worksheet names, in the same order as in the Excel file.
The first name in the list corresponds to sheet number 1.

=head2 active_sheet

  my $active_sheet_number = $reader->active_sheet;

Returns the numerical index (starting at 1) of the sheet that was active when the file was last saved.
May return C<undef>.

=head2 values

  my ($ref, $grid) = $reader->values($sheet);
  # or 
  my $grid = $reader->values($sheet);

Returns a pair where

=over

=item * 

the first item is a string that describes the range of the sheet,
in Excel A1 format (like for example C<A1:F12>

=item *

the second item is a bidimensional array of scalars (in other words,
an arrayref of arrayrefs of scalars), corresponding to cell
values in the specified worksheet. 


=back

The C<$sheet> argument can be either a sheet name or a sheet position (starting at 1).

When called in scalar context, this method only returns the grid of values.

Unlike the original Excel cells, positions in the grid are zero-based,
so for example the content of cell B3 is in C<< $grid->[1][2] >>.
The grid is sparse : the size of each row depends on the
position of the last non-empty cell in that row.
Thanks to Perl's auto-vivification mechanism, any attempt to access
a non-existent cell will automatically create the corresponding cell
within the grid. The number of rows and columns in the grid can be computed
like this :

  my $nb_rows = @$grid;
  my $nb_cols = max map {scalar @$_} @$grid; # must import List::Util::max

Alternatively, these numbers can also be obtained through the L</range_from_ref> method.


=head2 ivalues

  my ($ref, $iterator) = $reader->ivalues($sheet);
  # or 
  my $iterator = $reader->ivalues($sheet);
  
  while (my $row = $iterator->()) {
    say join ", ", @$row;
  }

Like the L</values> method, except that it returns an iterator instead of a fully populated data grid.
Data rows are retrieved through successive calls to the iterator.


=head2 table_names

  my @table_names = $reader->table_names;

Returns the list of names of tables registered in this workbook.

=head2 table

  my $rows             = $reader->table(name => $table_name);  # or just : $reader->table($table_name)
  # or
  my ($columns, $rows) = $reader->table(name => $table_name);
  # or
  my ($columns, $rows) = $reader->table(sheet => $sheet [, ref          => $ref] 
                                                        [, columns      => \@columns]
                                                        [, no_headers   => 1]
                                                        [, with_totals  => 1]
                                                        [, want_records => 0]
                                       );

In its simplest form, this method returns the content of an Excel table referenced by its table name
(in Excel, the table name appears and can be modified through the ribbon tab 
entry "Table tools / Design").
The table name is passed either through the named argument C<name>, or positionally as unique argument
to the method.

In list context, the method returns a pair, where the first element is
an arrayref of column names, and the second element is an arrayref of rows.
In scalar context, the method just returns the arrayref of rows. 

Rows are normally returned as hashrefs, where keys of the hashes correspond to column names
in the table. Under option C<< want_records => 0>>, rows are returned as arrayrefs, and it is up
to the client to make the correspondance with column names in C<$columns>.

Instead of specifying a table name, it is also possible to give a sheet name or sheet number.
By default, this considers the whole sheet content as a single table, where column names
are on the first row. However, additional arguments can be supplied to change the default
behaviour :

=over

=item ref

a specific range of cells within the sheet that contain the table rows and columns.
The range must be expressed using traditional Excel notation,
like for example C<"C9:E23"> (columns 3 to 5, rows 9 to 23).

=item columns

an arrayref containing the list of column names.
If absent, column names will be taken from the first row in the table.

=item no_headers

if true, the first row in the table will be treated as a regular data row, instead
of being treated as a list of column names. In that case, since column names cannot
be inferred from cell values in the first row, the C<columns> argument to the method
must be present.

=item with_totals

For tables that have a "totals" row (turned on by a specific checkbox
in the Excel ribbon), this row is normally not included in the result.
To include it as a final row, pass a true value to the C<with_totals> option.

=back


=head1 AUXILIARY METHODS

=head2 A1_to_num

  my $col_num = $reader->A1_to_num('A');    #   1
     $col_num = $reader->A1_to_num('AZ');   #  52
     $col_num = $reader->A1_to_num('AA');   #  26
     $col_num = $reader->A1_to_num('ABC');  # 731

Converts a column expressed as a sequence of capital letters (in Excel's "A1" notation)
into the corresponding numeric value.

The module also has a global hash C<$Excel::ValueReader::XLSX::A1_to_num_memoized> where
results from such conversions are memoized.

=head2 range_from_ref

  my ($col1, $row1, $col2, $row2) = $reader->range_from_ref("C4:BB123");

Returns the coordinates of the topleft and bottomright cells corresponding to a given Excel range.


=head2 table_info

  my $info = $reader->table_info->{$table_name};

Returns information about an Excel table in the form of a hashref with keys

=over

=item name

the name of the table

=item ref

the range of the table, in Excel notation (e.g "G6:Z44")

=item columns

an arrayref of column names

=item id

numerical id of the table

=item sheet

numerical id of the sheet to which the table belongs

=item no_headers

boolean flag corresponding to the negation of the checkbox "Headers row" in Excel.
By default tables have a header row, both in Excel and in this module.

=item has_totals

boolean flag corresponding to the checkbox "Totals row" in Excel.
By default tables have no totals row, both in Excel and in this module.


=back


=head2 formatted_date

  my $date = $reader->formatted_date($numeric_date, $excel_date_format);

Given a numeric date, this method returns a string date formatted according
to the I<date formatter> routine explained in the next section. The C<$excel_date_format>
argument should be the Excel format string for that specific cell; it is used
only for for deciding if the numeric value should be presented as a date, as a time,
or both. Optionally, a custom date formatter callback could be passed as third argument.






=head1 DATE AND TIME FORMATS

=head2 Date and time handling

In Excel, date and times values are stored as numeric values, where the integer part
represents the date, and the fractional part represents the time. What distinguishes
such numbers from ordinary numbers is the I<numeric format> applied to the cells
where they appear.

Numeric formats in Excel are complex to reproduce, in particular
because they are locale-dependent; therefore the present module does not attempt
to faithfully interpret Excel formats. It just infers from formats which
cells should be presented as date and/or time values. All such values are then
presented through the same I<date_formatter> routine. The default formatter
is based on L<POSIX/strftime>; other behaviours may be specified through the C<date_formatter>
parameter (explained below).

=head2 Parameters for the default strftime formatter

When using the default strftime formatter, the following parameters may be passed
to the constructor :

=over

=item date_format

The L<POSIX/strftime> format for representing dates. The default is C<%d.%m.%Y>.

=item time_format

The L<POSIX/strftime> format for representing times. The default is C<%H:%M:%S>.

=item datetime_format

The L<POSIX/strftime> format for representing date and time together.
The default is the concatenation of C<date_format> and C<time_format>, with
a space in between.

=back


=head2 Writing a custom formatter

A custom algorithm for date formatting can be specified as a parameter to the constructor

  my $reader = Excel::ValueReader::XLSX->new(xlsx           => $filename,
                                             date_formatter => sub {...});

If this parameter is C<undef>, date formatting is canceled and therefore date and
time values will be presented as plain numbers.

If not C<undef>, the date formatting routine will we called as :

  $date_formater->($excel_date_format, $year, $month, $day, $hour, $minute, $second, $millisecond);

where

=over

=item *

C<$excel_date_format> is the Excel numbering format associated to that cell, like for example
C<mm-dd-yy> or C<h:mm:ss AM/PM>. See the Excel documentation for the syntax description.
This is useful to decide if the value should be presented as a date, a time, or both.
The present module uses a simple heuristic : if the format contains C<d> or C<y>, it should
be presented as a date; if the format contains C<h> or C<s>, it should be presented
as a time. The letter C<m> is not taken into consideration because it is ambiguous :
depending on the position in the format string, it may represent either a "month" or a "minute".

=item *

C<year> is the full year, such as 1993 or 2021. The date system of the Excel file (either 1900 or 1904,
see L<https://support.microsoft.com/en-us/office/date-systems-in-excel-e7fe7167-48a9-4b96-bb53-5612a800b487>)
is properly taken into account. Excel has no support for dates prior to 1900 or 1904, so the
C<year> component will always be above this value.

=item *

C<month> is the numeric value of the month, starting at 1

=item *

C<day> is the numeric value of the day in month, starting at 1

=item *

C<$hour>, C<$minute>, C<$second>, C<$millisecond> obviously contain the corresponding
numeric values.

=back


=head1 CAVEATS

=over

=item *

This module was optimized for speed, not for completeness of
OOXML-SpreadsheetML support; so there may be some edge cases where the
output is incorrect with respect to the original Excel data.

=item *

Embedded newline characters in strings are stored in Excel as C<< \r\n >>,
following the old Windows convention. When retrieved through the C<Regex>
backend, the result contains the original C<< \r >> and C<< \n >> characters;
but when retrieved through the C<LibXML> backend, C<< \r >> are silently removed by the
C<XML::LibXML> package.

=back

=head1 SEE ALSO

The official reference for OOXML-SpreadsheetML format is in
L<https://www.ecma-international.org/publications/standards/Ecma-376.htm>.

Introductory material on XLSX file structure can be found at
L<http://officeopenxml.com/anatomyofOOXML-xlsx.php>.

Concurrent modules L<Spreadsheet::ParseXLSX> or L<Data::XLSX::Parser>.

Another unpublished but working module for parsing Excel files in Perl
can be found at L<https://github.com/jmcnamara/excel-reader-xlsx>.
Some test cases were borrowed from that distribution.

Conversions from and to Excel internal date format can also be performed
through the L<DateTime::Format::Excel> module.

=head1 BENCHMARKS

Below are some comparative figures. The task
computed here was to read a large Excel file with 800131 rows of 7 columns,
and report the total number of rows. Reported figures are in seconds.

  Spreadsheet::ParseXLSX                     1272 elapsed, 870 cpu, 4 system
  Data::XLSX::Parser                          125 elapsed, 107 cpu, 1 system
  Excel::ValueReader::XLSX::Regex              40 elapsed,  32 cpu, 0 system
  Excel::ValueReader::XLSX::Regex, iterator    34 elapsed,  30 cpu, 0 system
  Excel::ValueReader::XLSX::LibXML            101 elapsed,  83 cpu, 0 system
  Excel::ValueReader::XLSX::LibXML, iterator   91 elapsed,  80 cpu, 0 system

=head1 ACKNOWLEDGMENTS

=over

=item * 

David Flink signaled (and fixed) a bug about strings with embedded newline characters, and
signaled that the 'r' attribute in cells is optional.

=item *

Ulibuck signaled bugs several minor bugs on the LibXML backend.

=item *

H.Merijn Brand suggested additions to the API and several improvements to the code source.

=item *

Ephraim Stevens signaled a bug in the table() method with 'ref' param.

=back


=head1 AUTHOR

Laurent Dami, E<lt>dami at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020-2025 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

