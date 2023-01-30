use 5.014;
package Excel::ValueWriter::XLSX;
use strict;
use warnings;
use utf8;
use Archive::Zip          qw/AZ_OK COMPRESSION_LEVEL_DEFAULT/;
use Scalar::Util          qw/looks_like_number/;
use List::Util            qw/none/;
use Params::Validate      qw/validate_with SCALAR SCALARREF UNDEF/;
use POSIX                 qw/strftime/;
use Date::Calc            qw/Delta_Days/;
use Carp                  qw/croak/;
use Encode                qw/encode_utf8/;

our $VERSION = '1.03';

#======================================================================
# GLOBALS
#======================================================================

my $DATE_STYLE = 1;                        # 0-based index into the <cellXfs> format for dates ..
                                           # .. defined in the styles() method

my $SHEET_NAME = qr(^[^\\/?*\[\]]{1,31}$); # valid sheet names: <32 chars, no chars \/?*[] 
my $TABLE_NAME = qr(^\w{3,}$);             # valid table names: >= 3 chars, no spaces


# specification in Params::Validate format for checking parameters to the new() method 
my %params_spec = (

  # date_regex : for identifying dates in data cells. Should capture into $+{d}, $+{m} and $+{y}.
  date_regex        => {type => SCALARREF|UNDEF, optional => 1, default =>
                         qr[^(?: (?<d>\d\d?)    \. (?<m>\d\d?) \. (?<y>\d\d\d\d)  # dd.mm.yyyy
                               | (?<y>\d\d\d\d) -  (?<m>\d\d?) -  (?<d>\d\d?)     # yyyy-mm-dd
                               | (?<m>\d\d?)    /  (?<d>\d\d?) /  (?<y>\d\d\d\d)) # mm/dd/yyyy
                             $]x},

  # bool_regex : for identifying booleans in data cells. If true, should capture into $1
  bool_regex        => {type => SCALARREF|UNDEF, optional => 1, default => qr[^(?:(TRUE)|FALSE)$]},

  compression_level => {type => SCALAR, regex => qr/^\d$/, optional => 1, default => COMPRESSION_LEVEL_DEFAULT},

 );


my %entity       = ( '<' => '&lt;', '>' => '&gt;', '&' => '&amp;' );
my $entity_regex = do {my $chars = join "", keys %entity; qr/[$chars]/};


#======================================================================
# CONSTRUCTOR
#======================================================================

sub new {
  my $class = shift;

  # check parameters and create $self
  my $self = validate_with( params      => \@_,
                            spec        => \%params_spec,
                            allow_extra => 0,
                           );

  # initial values for internal data structures
  $self->{sheets}                = []; # array of sheet names
  $self->{tables}                = []; # array of table names
  $self->{shared_string}         = {}; # ($string => $string_index)
  $self->{n_strings_in_workbook} = 0;  # total nb of strings (including duplicates)
  $self->{last_string_id}        = 0;  # index for the next shared string
  $self->{defined_names}         = {}; # ($name => [$formula, $comment])

  # immediately open a Zip archive
  $self->{zip} = Archive::Zip->new;

  # return the constructed object
  bless $self, $class;
}


#======================================================================
# GATHERING DATA
#======================================================================


sub add_sheet {
  # 3rd parameter ($headers) may be omitted -- so we insert an undef if necessary
  splice @_, 3, 0, undef if @_ < 5;

  # now we can parse the parameters
  my ($self, $sheet_name, $table_name, $headers, $code_or_array) = @_;

  # check if the given sheet name is valid
  $sheet_name =~ $SHEET_NAME
    or croak "'$sheet_name' is not a valid sheet name";
  none {$sheet_name eq $_} @{$self->{sheets}}
    or croak "this workbook already has a sheet named '$sheet_name'";

  # local copies for convenience
  my $date_regex = $self->{date_regex};
  my $bool_regex = $self->{bool_regex};

  # iterator for generating rows; either received as argument or built as a closure upon an array
  my $next_row 
    = ref $code_or_array eq 'CODE'  ? $code_or_array
    : ref $code_or_array ne 'ARRAY' ? croak 'add_sheet() : missing or invalid $rows argument'
    : do {my $i = 0; sub { $i < @$code_or_array ? $code_or_array->[$i++] : undef}};

  # if $headers were not given explicitly, the first row will do
  $headers //= $next_row->();

  # array of column references in A1 Excel notation
  my @col_letters = ('A'); # this array will be expanded on demand in the loop below

  # register the sheet name 
  push @{$self->{sheets}}, $sheet_name;

  # start building XML for the sheet
  my @xml = (
    q{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>},
    q{<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"},
              q{ xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">},
    q{<sheetData>},
    );

  # loop over rows and columns
  my $row_num = 0;
 ROW:
  for (my $row = $headers; $row; $row = $next_row->()) {
    $row_num++;
    my $last_col = @$row or next ROW;
    my @cells;

  COLUMN:
    foreach my $col (0 .. $last_col-1) {

      # if this column letter is not known yet, compute it using Perl's increment op on strings
      my $col_letter = $col_letters[$col]
                   //= do {my $prev_letter = $col_letters[$col-1]; ++$prev_letter};

      # get the value; if the cell is empty, no need to write it into the XML
      my $val = $row->[$col];
      defined $val and length $val or next COLUMN;

      # choose XML attributes and inner value
      (my $tag, my $attrs, $val)
        = looks_like_number $val             ? (v => ""                  , $val                          )
        : $date_regex && $val =~ $date_regex ? (v => qq{ s="$DATE_STYLE"}, n_days($+{y}, $+{m}, $+{d})   )
        : $bool_regex && $val =~ $bool_regex ? (v => qq{ t="b"}          , $1 ? 1 : 0                    )
        : $val =~ /^=/                       ? (f => "",                   escape_formula($val)          )
        :                                      (v => qq{ t="s"}          , $self->add_shared_string($val));

      # add the new XML cell
      my $cell = sprintf qq{<c r="%s%d"%s><%s>%s</%s></c>}, $col_letter, $row_num, $attrs, $tag, $val, $tag;
      push @cells, $cell;
    }

    # generate the row XML and add it to the sheet
    my $row_xml = join "", qq{<row r="$row_num" spans="1:$last_col">}, @cells, qq{</row>};
    push @xml, $row_xml;
  }

  # close sheet data
  push @xml, q{</sheetData>};

  # if required, add the table corresponding to this sheet into the zip archive, and refer to it in XML
  my @table_rels;
  if ($table_name && $row_num) {
    my $table_id = $self->add_table($table_name, $col_letters[-1], $row_num, @$headers);
    push @table_rels, $table_id;
    push @xml, q{<tableParts count="1"><tablePart r:id="rId1"/></tableParts>};
  }

  # close the worksheet xml
  push @xml, q{</worksheet>};

  # insert the sheet and its rels into the zip archive
  my $sheet_id   = $self->n_sheets;
  my $sheet_file = "sheet$sheet_id.xml";
  $self->{zip}->addString(encode_utf8(join("", @xml)),
                          "xl/worksheets/$sheet_file",
                          $self->{compression_level});
  $self->{zip}->addString($self->worksheet_rels(@table_rels),
                          "xl/worksheets/_rels/$sheet_file.rels",
                          $self->{compression_level});

  return $sheet_id;
}



sub add_sheets_from_database {
  my ($self, $dbh, $sheet_prefix, @table_names) = @_;

  # in absence of table names, get them from the database metadata
  if (!@table_names) {
    my $tables = $dbh->table_info(undef, undef, undef, 'TABLE')->fetchall_arrayref({});
    @table_names = map {$_->{TABLE_NAME}} @$tables;
  }

  $sheet_prefix //= "S.";

  foreach my $table (@table_names) {
    my $sth = $dbh->prepare("select * from $table");
    $sth->execute;
    my $headers = $sth->{NAME};
    my $rows    = $sth->fetchall_arrayref;
    $self->add_sheet("$sheet_prefix$table", $table, $headers, $rows);
  }
}



sub add_shared_string {
  my ($self, $string) = @_;

  # single quote before an initial equal sign is ignored (escaping the '=' like in Excel)
  $string =~ s/^'=/=/;

  # keep a global count of how many strings are in the workbook
  $self->{n_strings_in_workbook}++;

  # if that string was already stored, return its id, otherwise create a new id
  $self->{shared_strings}{$string} //= $self->{last_string_id}++;
}



sub add_table {
  my ($self, $table_name, $last_col, $last_row, @col_names) = @_;

  # check if the given table name is valid
  $table_name =~ $TABLE_NAME
    or croak "'$table_name' is not a valid table name";
  none {$table_name eq $_} @{$self->{tables}}
    or croak "this workbook already has a table named '$table_name'";

  # register this table
  push @{$self->{tables}}, $table_name;
  my $table_id = $self->n_tables;

  # build column headers from first data row
  unshift @col_names, undef; # so that the first index is at 1, not 0
  my @columns = map {qq{<tableColumn id="$_" name="$col_names[$_]"/>}} 1 .. $#col_names;

  # Excel range of this table
  my $ref = "A1:$last_col$last_row";

  # assemble XML for the table
  my @xml = (
    qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>},
    qq{<table xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"}.
         qq{ id="$table_id" displayName="$table_name" ref="$ref" totalsRowShown="0">},
    qq{<autoFilter ref="A1:D4"/>},
    qq{<tableColumns count="$#col_names">},
    @columns,
    qq{</tableColumns>},
    qq{<tableStyleInfo name="TableStyleMedium2" showFirstColumn="0" showLastColumn="0" showRowStripes="1" showColumnStripes="0"/>},
    qq{</table>},
   );

  # insert into the zip archive
  $self->{zip}->addString(encode_utf8(join "", @xml),
                          "xl/tables/table$table_id.xml",
                          $self->{compression_level});

  return $table_id;
}


sub add_defined_name {
  my ($self, $name, $formula, $comment) = @_;

  $name && $formula                        or croak 'add_defined_name($name, $formula): empty argument'; 
  not exists $self->{defined_names}{$name} or croak "add_defined_name(): name '$name' already in use";
  $self->{defined_names}{$name} = [$formula, $comment];
}


sub worksheet_rels {
  my ($self, $table_id) = @_;

  my @rels;
  push @rels, "officeDocument/2006/relationships/table" => "../tables/table$table_id.xml" if $table_id;
  return $self->relationships(@rels);
}


#======================================================================
# BUILDING THE ZIP CONTENTS
#======================================================================

sub save_as {
  my ($self, $target) = @_;

  # assemble all parts within the zip, except sheets and tables that were already added previously
  my $zip = $self->{zip};
  $zip->addString($self->content_types,  "[Content_Types].xml"        , $self->{compression_level});
  $zip->addString($self->core,           "docProps/core.xml"          , $self->{compression_level});
  $zip->addString($self->app,            "docProps/app.xml"           , $self->{compression_level});
  $zip->addString($self->workbook,       "xl/workbook.xml"            , $self->{compression_level});
  $zip->addString($self->_rels,          "_rels/.rels"                , $self->{compression_level});
  $zip->addString($self->workbook_rels,  "xl/_rels/workbook.xml.rels" , $self->{compression_level});
  $zip->addString($self->shared_strings, "xl/sharedStrings.xml"       , $self->{compression_level});
  $zip->addString($self->styles,         "xl/styles.xml"              , $self->{compression_level});

  # write the Zip archive
  my $write_result = ref $target ? $zip->writeToFileHandle($target) : $zip->writeToFileNamed($target);
  $write_result == AZ_OK
    or croak "could not save Zip archive into " . (ref($target) || $target);
}


sub _rels {
  my ($self) = @_;

  return $self->relationships("officeDocument/2006/relationships/extended-properties" => "docProps/app.xml",
                              "package/2006/relationships/metadata/core-properties"   => "docProps/core.xml",
                              "officeDocument/2006/relationships/officeDocument"      => "xl/workbook.xml");
}

sub workbook_rels {
  my ($self) = @_;

  my @rels = map {("officeDocument/2006/relationships/worksheet"     => "worksheets/sheet$_.xml")}
                 1 .. $self->n_sheets;
  push @rels,      "officeDocument/2006/relationships/sharedStrings" => "sharedStrings.xml",
                   "officeDocument/2006/relationships/styles"        => "styles.xml";

  return $self->relationships(@rels);
}


sub workbook {
  my ($self) = @_;

  # opening XML
  my @xml = (
    qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>},
    qq{<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"},
             qq{ xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">},
    );

  # references to the worksheets
  push @xml, q{<sheets>};
  my $sheet_id = 1;
  foreach my $sheet_name (@{$self->{sheets}}) {
    push @xml, qq{<sheet name="$sheet_name" sheetId="$sheet_id" r:id="rId$sheet_id"/>};
    $sheet_id++;
  }
  push @xml, q{</sheets>};

  if (my $names = $self->{defined_names}) {
    push @xml, q{<definedNames>};
    while (my ($name, $content) = each %$names) {
      my $attrs = qq{name="$name"};
      $attrs   .= qq{ comment="$content->[1]"} if $content->[1];
      $content->[0] =~ s/($entity_regex)/$entity{$1}/g;
      push @xml, qq{<definedName $attrs>$content->[0]</definedName>};
    }
    push @xml, q{</definedNames>};
  }


  # closing XML
  push @xml, q{</workbook>};

  return encode_utf8(join "", @xml);
}


sub content_types {
  my ($self) = @_;

  my $spreadsheetml = "application/vnd.openxmlformats-officedocument.spreadsheetml";

  my @sheets_xml
    = map {qq{<Override PartName="/xl/worksheets/sheet$_.xml" ContentType="$spreadsheetml.worksheet+xml"/>}} 1 .. $self->n_sheets;

  my @tables_xml
    = map {qq{  <Override PartName="/xl/tables/table$_.xml" ContentType="$spreadsheetml.table+xml"/>}} 1 .. $self->n_tables;

  my @xml = (
    qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>},
    qq{<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">},
    qq{<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>},
    qq{<Default Extension="xml" ContentType="application/xml"/>},
    qq{<Override PartName="/xl/workbook.xml" ContentType="$spreadsheetml.sheet.main+xml"/>},
    qq{<Override PartName="/xl/styles.xml" ContentType="$spreadsheetml.styles+xml"/>},
    qq{<Override PartName="/xl/sharedStrings.xml" ContentType="$spreadsheetml.sharedStrings+xml"/>},
    qq{<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>},
    qq{<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>},
    @sheets_xml,
    @tables_xml,
    qq{</Types>},
   );

  return join "", @xml;
}


sub core {
  my ($self) = @_;

  my $now = strftime "%Y-%m-%dT%H:%M:%SZ", gmtime;

  my @xml = (
    qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>},
    qq{<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" },
                      qq{ xmlns:dc="http://purl.org/dc/elements/1.1/"},
                      qq{ xmlns:dcterms="http://purl.org/dc/terms/"},
                      qq{ xmlns:dcmitype="http://purl.org/dc/dcmitype/"},
                      qq{ xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">},
    qq{<dcterms:created xsi:type="dcterms:W3CDTF">$now</dcterms:created>},
    qq{<dcterms:modified xsi:type="dcterms:W3CDTF">$now</dcterms:modified>},
    qq{</cp:coreProperties>},
   );

  return join "", @xml;
}

sub app {
  my ($self) = @_;

  my @xml = (
    qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>},
    qq{<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"},
               qq{ xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">},
    qq{<Application>Microsoft Excel</Application>},
    qq{</Properties>},
   );

  return join "", @xml;
}




sub shared_strings {
  my ($self) = @_;

  # array of XML nodes for each shared string
  my @si_nodes;
  $si_nodes[$self->{shared_strings}{$_}] = si_node($_) foreach keys %{$self->{shared_strings}};

  # assemble XML
  my @xml = (
    qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>},
    qq{<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"},
         qq{ count="$self->{n_strings_in_workbook}" uniqueCount="$self->{last_string_id}">},
    @si_nodes,
    qq{</sst>},
   );

  return encode_utf8(join "", @xml);
}


sub styles {
  my ($self) = @_;

  # minimal stylesheet
  # style "1" will be used for displaying dates; it uses the default numFmtId for dates, which is 14 (Excel builtin).
  # other nodes are empty but must be present
  my @xml = (
    q{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>},
    q{<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">},
    q{<fonts count="1"><font/></fonts>},
    q{<fills count="1"><fill/></fills>},
    q{<borders count="1"><border/></borders>},
    q{<cellStyleXfs count="1"><xf/></cellStyleXfs>},
    q{<cellXfs count="2"><xf/><xf numFmtId="14" applyNumberFormat="1"/></cellXfs>},
    q{<tableStyles count="0" defaultTableStyle="TableStyleMedium2" defaultPivotStyle="PivotStyleLight16"/>},
    q{</styleSheet>},
   );

  my $xml = join "", @xml;

  return $xml;
}


#======================================================================
# UTILITY METHODS
#======================================================================

sub relationships {
  my ($self, @rels) = @_;

  # build a "rel" file from a list of relationships
  my @xml = (
    qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>},
    qq{<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">},
   );

  my $id = 1;
  while (my ($type, $target) = splice(@rels, 0, 2)) {
    push @xml, qq{<Relationship Id="rId$id" Type="http://schemas.openxmlformats.org/$type" Target="$target"/>};
    $id++;
  }

  push @xml, qq{</Relationships>};

  return join "", @xml;
}


sub n_sheets {
  my ($self) = @_;
  return scalar @{$self->{sheets}};
}

sub n_tables {
  my ($self) = @_;
  return scalar @{$self->{tables}};
}


#======================================================================
# UTILITY ROUTINES
#======================================================================


sub si_node {
  my ($string) = @_;

  # build XML node for a single shared string
  $string =~ s/($entity_regex)/$entity{$1}/g;
  my $maybe_preserve_space = $string =~ /^\s|\s$/ ? ' xml:space="preserve"' : '';
  my $node = qq{<si><t$maybe_preserve_space>$string</t></si>};

  return $node;
}

sub escape_formula {
  my ($string) = @_;

  $string =~ s/^=//;
  $string =~ s/($entity_regex)/$entity{$1}/g;
  return $string;
}


sub n_days {
  my ($y, $m, $d) = @_;

  # convert the given date into a number of days since 1st January 1900
  my $n_days = Delta_Days(1900, 1, 1, $y, $m, $d) + 1;
  my $is_after_february_1900 = $n_days > 59;
  $n_days += 1 if $is_after_february_1900; # because Excel wrongly treats 1900 as a leap year

  return $n_days;
}





1;

__END__

=encoding utf-8

=head1 NAME

Excel::ValueWriter::XLSX - generating data-only Excel workbooks in XLSX format, fast

=head1 SYNOPSIS

  my $writer = Excel::ValueWriter::XLSX->new;
  $writer->add_sheet($sheet_name1, $table_name1, [qw/a b tot/], [[1, 2, '=[a]+[b]'],
                                                                 [3, 4],
                                                                 ['TRUE', 'FALSE'],
                                                                ]);
  $writer->add_sheet($sheet_name2, $table_name2, \@headers, $row_generator);
  $writer->add_sheets_from_database($dbh);
  $writer->add_defined_name($name, $formula, $comment);
  $writer->save_as($filename);
  
  $writer = Excel::ValueWriter::XLSX->new(bool_regex => qr[^(?:(VRAI)|FAUX)$]);
  $writer->add_sheet($sheet_name1, $table_name1, [qw/a b/], [['I like Perl:', 'VRAI']]);


=head1 DESCRIPTION

The present module is aimed at fast and cost-effective
production of "data-only" Excel workbooks, containing nothing but plain values
and formulas.

CPU and memory usage are much lower than with the well-known L<Excel::Writer::XLSX>;
however the set of features is also much more restricted : there is no support
for formats, colors, figures or other fancy Excel features.

Such workbooks with plain data are useful for example :

=over 

=item *

in architectures where Excel is used merely as a local database, for
example in connection with a Power Pivot architecture (for that purpose,
see also the companion module L<Excel::PowerPivot::Utils>);

=item *

for fine tuning of the ZIP compression level to be applied
to the generated C<.xlsx> file;

=item *

for generating files with large amounts of data (this was the original
motivation for writing this module, because
L<Excel::Writer::XLSX> tends to become very slow on files with large
numbers of rows).

=back


=head1 METHODS

=head2 new

  my $writer = Excel::ValueWriter::XLSX->new(%options);

Constructor for a new writer object. Options are :

=over

=item date_regex

A compiled regular expression for detecting data cells that contain dates.
The default implementation recognizes dates in C<dd.mm.yyyy>, C<yyyy-mm-dd>
and C<mm/dd/yyyy> formats. User-supplied regular expressions should use
named captures so that the day, month and year values can be found respectively
in C<< $+{d} >>, C<< $+{m} >> and C<< $+{y} >>.

=item bool_regex

A compiled regular expression for detecting data cells that contain boolean values.
The default implementation recognizes uppercase strings 'TRUE' or 'FALSE' as booleans.
User-supplied regular expressions should put the word corresponding to 'TRUE' within
parenthesis so that the content is captured in C<$1>. Here is an example for french :

  $writer = Excel::ValueWriter::XLSX->new(bool_regex => qr[^(?:(VRAI)|FAUX)$]);


=item compression_level

A number from 0 (no compression) to 9 (maximum compression) specifying
the desired ZIP compression level. High values produce smaller files but
consume more CPU. The default is taken from COMPRESSION_LEVEL_DEFAULT in
L<Archive::Zip>, which amounts to 6.

=back

=head2 add_sheet

  $writer->add_sheet($sheet_name, $table_name, [$headers,] $rows);

Adds a new worksheet into the workbook.

=over

=item *

The C<$sheet_name> is mandatory; it must be unique and between 1 and 31 characters long.

=item *

If C<$table_name> is not C<undef>, the sheet contents will be registered as an
L<Excel table|https://support.microsoft.com/en-us/office/overview-of-excel-tables-7ab0bb7d-3a9e-4b56-a3c9-6c94334e492c> of that name. Excel tables offer more features than regular ranges of cells,
so generally it is a good idea to always assign a table name.
Table names must be unique, of minimum 3 characters, without spaces or special characters.
Technically table names could be equal to sheet names, but this is
not recommended because it may create confusion if the data is later to
be referred to from Power Query or from Power Pivot.

=item *

The C<$headers> argument is optional; it may be C<undef> or may even be absent.
If present, it should contain an arrayref of scalar values, that will
be used as column names for the table associated with that worksheet.
Column names should be unique (otherwise Excel will automatically add
a discriminating number). If C<$headers> are not present, the first
row in C<$rows> will be treated as headers.


=item *

The C<$rows> argument may be either a reference to a 2-dimensional array of values,
or a reference to a callback function that will return a new row at each call, in the
form of a 1-dimensional array reference. An empty return from the callback
function signals the end of data (but intermediate empty rows may be returned
as C<< [] >>). Callback functions should typically be I<closures> over a lexical
variable used to decide when the last row has been met. Here is an example of a
callback function used to feed a sheet with 500 lines of 300 columns of random numbers:

  my @headers_for_rand = map {"h$_"} 1 .. 300;
  my $random_rows = do {my $count = 500; sub {$count-- > 0 ? [map {rand()} 1 .. 300] : undef}};
  $writer->add_sheet(RAND_SHEET => rand => \@headers_for_rand, $random_rows);

=back

Cells within a row must contain scalar values. Values that look like numbers are treated
as numbers. String values that match the C<date_regex> are converted into numbers and
displayed through a date format. String values that start with an initial '=' are treated
as formulas; but like in Excel, if you want regular string that starts with a '=', put a single
quote just before the '=' -- that single quote will be removed from the string.
Everything else is treated as a string. Strings are shared at the
workbook level (hence a string that appears several times in the input data will be stored
only once within the workbook).

=head2 add_sheets_from_database

  $writer->add_sheets_from_database($dbh, $sheet_prefix, @table_names);

Gets data from database tables and adds them as sheets into the Excel workbook.
Arguments are :

=over

=item C<$dbh>

An active L<DBI> database handle

=item C<$sheet_prefix>

A string that will be prepended at the beginning of each worksheet name,
so that they are different from names of Excel tables.
The default is 'S.'.

=item C<@table_names>

The list of tables to be read from the database.
If empty, table names are retrieved automatically from the database
through the L<DBI/table_info> method.

=back

=head2 add_defined_name

  $writer->add_defined_name($name, $formula, $comment);

Adds a "defined name" to the workbook. Defined names can be used
in any formula within the workbook, and will be replaced by
the corresponding content.

=over

=item *

C<$name> is mandatory and must be unique

=item *

C<$formula> is mandatory and will be interpreted by Excel like a formula.
References to ranges should include the sheet name and use absolute coordinates;
for example for concatenating two cells in sheet 's1', the formula is :

  $writer->add_defined_name(cells_1_and_2 => q{'s1'!$A$1&'s1'!$A$2});

If the intended content is just a constant string, it must be enclosed in double quotes, i.e.

  $writer->add_defined_name(my_string => q{"my_constant_value"});

=item *

C<$comment> is optional; it will appear when users consult the 
L<name manager|https://support.microsoft.com/en-us/office/use-the-name-manager-in-excel-4d8c4c2b-9f7d-44e3-a3b4-9f61bd5c64e4> in the Formulas tab.

=back


=head2 save_as

  $writer->save_as($target);

Writes the workbook contents into the specified C<$target>, which can be either
a filename or filehandle opened for writing.


=head1 ARCHITECTURAL NOTES

=head2 Object-orientedness

Although I'm a big fan of L<Moose> and its variants, the present module is implemented
in POPO (Plain Old Perl Object) : since the aim is to maximize cost-effectiveness, and since
the object model is extremely simple, there was no ground for using a sophisticated object system.

=head2 Benchmarks

I did a couple of measurements that demonstrate the effectiveness of this
module on large datasets; but the results cannot be included into this distribution yet,
because the tests are not sufficiently formalized and they are based on
on data that is not public.

=head2 To do

  - options for workbook properties : author, etc.
  - support for 1904 date schema
  - reproducible benchmarks

=head1 SEE ALSO

L<Excel::Writer::XLSX>, L<Excel::PowerPivot::Utils>.

=head1 AUTHOR

Laurent Dami, E<lt>dami at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2022, 2023 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
