package Excel::ValueReader::XLSX;
use utf8;
use Moose;
use Archive::Zip          qw(AZ_OK);
use Module::Load          qw/load/;
use feature 'state';

our $VERSION = '1.0';

#======================================================================
# ATTRIBUTES
#======================================================================

# public attributes
has 'xlsx'      => (is => 'ro', isa => 'Str', required => 1);
has 'using'     => (is => 'ro',   isa => 'Str', default => 'Regex');

# attributes used internally, not documented
has 'zip'       => (is => 'ro',   isa => 'Archive::Zip', init_arg => undef,
                    builder => '_zip',   lazy => 1);
has 'sheets'    => (is => 'ro',   isa => 'HashRef', init_arg => undef,
                    builder => '_sheets',   lazy => 1);
has 'strings'   => (is => 'ro',   isa => 'ArrayRef', init_arg => undef,
                    builder => '_strings',   lazy => 1);
has 'backend'   => (is => 'ro',   isa => 'Object',
                    builder => '_backend',   lazy => 1,
                    handles => [qw/_strings _sheets values/]);

#======================================================================
# BUILDING
#======================================================================

# syntactic sugar for supporting ->new($path) instead of ->new(xlsx => $path)
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  if ( @_ == 1 && !ref $_[0] ) {
    return $class->$orig(xlsx => $_[0]);
  }
  else {
    return $class->$orig(@_);
  }
};


#======================================================================
# LAZY ATTRIBUTE CONSTRUCTORS
#======================================================================

sub _zip {
  my $self = shift;

  my $zip = Archive::Zip->new;
  $zip->read($self->{xlsx}) == AZ_OK
      or die "cannot unzip $self->{xlsx}";

  return $zip;
}


sub _backend {
  my $self = shift;

  my $backend_class = ref($self) . '::' . $self->using;
  load $backend_class;

  return $backend_class->new(frontend => $self);
}


#======================================================================
# METHODS
#======================================================================

sub sheet_names {
  my ($self) = @_;

  my $sheets = $self->sheets;

  return sort {$sheets->{$a} <=> $sheets->{$b}} keys %$sheets;
}



sub _member_contents {
  my ($self, $member) = @_;

  my $contents = $self->zip->contents($member)
    or die "no contents for member $member";
  utf8::decode($contents);

  return $contents;
}



sub sheet_member {
  my ($self, $sheet) = @_;

  # check that sheet name was given
  $sheet or die "->values(): missing sheet name";

  # get sheet id
  my $id = $self->sheets->{$sheet};
  $id //= $sheet if $sheet =~ /^\d+$/;
  $id or die "no such sheet: $sheet";

  # construct member name for that sheet
  return "xl/worksheets/sheet$id.xml";
}


sub A1_to_num { # convert Excel A1 reference format to a number
  my ($self, $string) = @_;;

  # ordinal number for character just before 'A'
  state $base = ord('A') - 1;

  # iterate on 'digits' (letters of the A1 cell reference)
  my $num = 0;
  foreach my $digit (map {ord($_) - $base} split //, $string) {
    $num = $num*26 + $digit;
  }

  return $num;
}


1;

__END__

=head1 NAME

Excel::ValueReader::XLSX - extracting values from Excel workbooks in XLSX format, fast

=head1 SYNOPSIS

  my $reader = Excel::ValueReader::XLSX->new(xlsx => $filename);
  # .. or with syntactic sugar :
  my $reader = Excel::ValueReader::XLSX->new($filename);
  # .. or with LibXML backend :
  my $reader = Excel::ValueReader::XLSX->new(xlsx => $filename,
                                             using => 'LibXML');
  
  foreach my $sheet_name ($reader->sheet_names) {
     my $grid = $reader->values($sheet_name);
     my $n_rows = @$grid;
     print "sheet $sheet_name has $n_rows rows; ",
           "first cell contains : ", $grid->[0][0];
  }

=head1 DESCRIPTION

This module reads the contents of an Excel file in XLSX format;
given a worksheet name it returns a bidimensional array of values
in that worksheet.

Unlike L<Spreadsheet::ParseXLSX> or L<Spreadsheet::XLSX>, there is no
support for reading formulas, formats or other Excel internal
information; all you get are plain values -- but you get them much
faster !

This front module has two different backends for extracting values :

=over

=item Regex (default)

this backend uses regular expressions to parse the XML content.

=item LibXML

this backend uses L<XML::LibXML::Reader> to parse the XML content.
It is probably safer but about three times slower than the Regex backend
(but still much faster than L<Spreadsheet::ParseXLSX>).

=back


=head1 METHODS

=head2 new

  my $reader = Excel::ValueReader::XLSX->new(xlsx  => $filename,
                                             using => $backend);

The C<xlsx> argument is mandatory and points to the C<.xlsx> file to be parsed.
The C<using> argument is optional; it specifies the backend to be used for parsing; 
default is 'Regex'.

As syntactic sugar, a shorter form is admitted :

  my $reader = Excel::ValueReader::XLSX->new($filename);


=head2 sheet_names

  my @sheets = $reader->sheet_names;

Returns the list of worksheet names, in the same order as in the Excel file.

=head2 values

  my $grid = $reader->values($sheet);

Returns a bidimensional array of scalars, corresponding to cell
values in the specified worksheet. The C<$sheet> argument can be either
a sheet name or a sheet position (starting at 1).

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


=head1 CAVEAT

This module was optimized for speed, not for completeness of
OOXML-SpreadsheetML support; so there may be some edge cases where the
output is incorrect with respect to the original Excel data.

Excel dates are stored internally as numbers, so they will appear as
numbers in the output. To convert numbers to dates, use the
L<DateTime::Format::Excel> module. Unfortunately the module has
currently no support for identifying which cells contain dates; this
would require to parse cell formats -- maybe this will be implemented
in a future release.


=head1 SEE ALSO

The official reference for OOXML-SpreadsheetML format is in
L<https://www.ecma-international.org/publications/standards/Ecma-376.htm>.

Introductory material on XLSX file structure can be found at
L<http://officeopenxml.com/anatomyofOOXML-xlsx.php>.

The CPAN module L<Data::XLSX::Parser> is claimed to be in alpha stage;
it seems to be working but the documentation is insufficient -- I had 
to inspect the test suite to understand how to use it.

Another unpublished but working module for parsing Excel files in Perl
can be found at L<https://github.com/jmcnamara/excel-reader-xlsx>.
Some test cases were borrowed from that distribution.


=head1 BENCHMARKS

Below are some benchmarks computed with the program C<benchmark.pl> in
this distribution. The task was to parse an Excel file of five worksheets
with about 62600 rows in total, and report the number of rows per sheet.
Reported figures are in seconds.

  Excel::ValueReader::XLSX::Regex    11 elapsed,  10 cpu, 0 system
  Excel::ValueReader::XLSX::LibXML   35 elapsed,  34 cpu, 0 system
  [unpublished] Excel::Reader::XLSX  39 elapsed,  37 cpu, 0 system
  Spreadsheet::ParseXLSX            244 elapsed, 240 cpu, 1 system
  Data::XLSX::Parser                 37 elapsed,  35 cpu, 0 system

These figures show that the regex version is about 3 times faster
than the LibXML version, and about 22 times faster than
L<Spreadsheet::ParseXLSX>. Tests with a bigger file of about 90000 rows
showed similar ratios.

Modules
C<Excel::Reader::XLSX> (unpublished) and L<Data::XLSX::Parser>
are based on L<XML::LibXML> like L<Excel::ValueReader::XLSX::LibXML>;
execution times for those three modules are very close.

=head1 AUTHOR

Laurent Dami, E<lt>dami at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
