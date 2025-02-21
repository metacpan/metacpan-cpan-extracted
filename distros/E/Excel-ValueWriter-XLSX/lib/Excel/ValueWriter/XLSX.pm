use 5.014;
package Excel::ValueWriter::XLSX;
use strict;
use warnings;
use utf8;
use Archive::Zip          qw/AZ_OK COMPRESSION_LEVEL_DEFAULT/;
use Scalar::Util          qw/looks_like_number blessed/;
use List::Util            qw/none/;
use POSIX                 qw/strftime/;
use Date::Calc            qw/Delta_Days/;
use Carp                  qw/croak/;
use Encode                qw/encode_utf8/;
use Data::Domain 1.16     qw/:all/;
use Try::Tiny;

our $VERSION = '1.09';

#======================================================================
# GLOBALS
#======================================================================

my $DATE_STYLE = 1;                           # 0-based index into the <cellXfs> format for dates ..
                                              # .. defined in the styles() method

my $RX_SHEET_NAME = qr(^[^\\/?*\[\]]{1,31}$); # valid sheet names: <32 chars, no chars \/?*[] 
my $RX_TABLE_NAME = qr(^\w{3,}$);             # valid table names: >= 3 chars, no spaces

my %entity       = ( '<' => '&lt;', '>' => '&gt;', '&' => '&amp;' );
my $entity_regex = do {my $chars = join "", keys %entity; qr/[$chars]/};

#======================================================================
# SIGNATURES FOR CONTROLLING ARGS TO PUBLIC METHODS
#======================================================================

my $sig_for_new = Struict( # Struict = strict Struct .. not a typo!

  # date_regex : for identifying dates in data cells. Should capture into $+{d}, $+{m} and $+{y}.
  date_regex        => Regexp(-if_absent =>
                         qr[^(?: (?<d>\d\d?)    \. (?<m>\d\d?) \. (?<y>\d\d\d\d)  # dd.mm.yyyy
                               | (?<y>\d\d\d\d) -  (?<m>\d\d?) -  (?<d>\d\d?)     # yyyy-mm-dd
                               | (?<m>\d\d?)    /  (?<d>\d\d?) /  (?<y>\d\d\d\d)) # mm/dd/yyyy
                             $]x),

  # bool_regex : for identifying booleans in data cells. If true, should capture into $1
  bool_regex        => Regexp(-if_absent => qr[^(?:(TRUE)|FALSE)$]),

  # ZIP compression level
  compression_level => Int(-range => [1, 9], -if_absent => COMPRESSION_LEVEL_DEFAULT),
 )->meth_signature;


my $sig_for_add_sheet = List(
  String(-name => 'sheet_name', -regex => $RX_SHEET_NAME),
  String(-name => 'table_name', -regex => $RX_TABLE_NAME, -optional => 1),
  List  (-name => 'headers',    -all => String,           -optional => 1),
  One_of(-name => 'rows_maker', -options => [List,                                      # an array of rows, or
                                             Coderef,                                   # a row generator coderef, or
                                             Obj(-isa => 'DBI::st'),                    # a DBI statement, or
                                             Obj(-isa => 'DBIx::DataModel::Statement'), # a DBIx::DataModel statement
                                            ]),
  Struict(-name => 'options', -optional => 1, -fields => {
      cols => One_of(List(-all => Num),
                     List(-all => Struct(width => Num(-optional => 1),
                                         style => Int(-optional => 1),
                                         min   => Int(-optional => 1),
                                         max   => Int(-optional => 1))))
    }),
 )->meth_signature;

my $sig_for_add_sheets_from_database = List(-items => [Obj   (-isa     => 'DBI::db'),
                                                       String(-default => "S.")],
                                            -all   => String,
 )->meth_signature;

my $sig_for_add_defined_name = List(String(-name => "name"),
                                    String(-name => "formula"),
                                    String(-name => "comments", -optional => 1),
  )->meth_signature;



my $sig_for_save_as = One_of(String,
                             Whatever(-does => 'IO'),
  )->meth_signature;


  
#======================================================================
# CONSTRUCTOR
#======================================================================

sub new {
  my ($class, %self) = &$sig_for_new;

  # initial values for internal data structures (constructor args cannot initialize those)
  $self{sheets}                = []; # array of sheet names
  $self{tables}                = []; # array of table names
  $self{shared_string}         = {}; # ($string => $string_index)
  $self{n_strings_in_workbook} = 0;  # total nb of strings (including duplicates)
  $self{last_string_id}        = 0;  # index for the next shared string
  $self{defined_names}         = {}; # ($name => [$formula, $comment])

  # immediately open a Zip archive
  $self{zip} = Archive::Zip->new;

  # return the constructed object
  bless \%self, $class;
}


#======================================================================
# GATHERING DATA
#======================================================================


sub add_sheet {
  # the 3rd parameter ($headers) may be omitted -- so we insert an undef if necessary
  splice @_, 3, 0, undef if @_ < 5 or @_ == 5 && (ref $_[4] // '') eq 'HASH';

  # now we can parse the parameters
  my ($self, $sheet_name, $table_name, $headers, $rows_maker, $options) = &$sig_for_add_sheet;

  # register the sheet name 
  none {$sheet_name eq $_} @{$self->{sheets}}
    or croak "this workbook already has a sheet named '$sheet_name'";
  push @{$self->{sheets}}, $sheet_name;

  # iterator for generating rows
  my $row_iterator = $self->_build_row_iterator($rows_maker, \$headers);

  # build inner XML
  my ($xml, $last_row, $last_col) = $self->_build_rows($headers, $row_iterator, $table_name);

  # add XML preamble and close sheet data
  my $preamble = join "", 
    q{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>},
    q{<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"},
              q{ xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">};
  $preamble .= $self->_xml_for_options($options) if $options;
  $preamble .= q{<sheetData>};
  substr $xml, 0, 0, $preamble;
  $xml .= q{</sheetData>};

  # if required, add the table corresponding to this sheet into the zip archive, and refer to it in XML
  my @table_rels;
  if ($table_name && $headers) {
    my $table_id = $self->_add_table($table_name, $last_col, $last_row, @$headers);
    push @table_rels, $table_id;
    $xml .= q{<tableParts count="1"><tablePart r:id="rId1"/></tableParts>};
  }

  # close the worksheet xml
  $xml .= q{</worksheet>};

  # insert the sheet and its rels into the zip archive
  my $sheet_id   = $self->n_sheets;
  my $sheet_file = "sheet$sheet_id.xml";
  $self->add_string_to_zip(encode_utf8($xml),                  "xl/worksheets/$sheet_file"           );
  $self->add_string_to_zip($self->worksheet_rels(@table_rels), "xl/worksheets/_rels/$sheet_file.rels");

  return $sheet_id;
}

sub _build_row_iterator {
  my ($self, $rows_maker, $headers_ref) = @_;

  my $iterator;

  my $ref = ref $rows_maker;
  if ($ref && $ref eq 'CODE') {
    $iterator  = $rows_maker;
    $$headers_ref //= $iterator->();
  }
  elsif ($ref && $ref eq 'ARRAY') {
    my $i = 0;
    $iterator  = sub { $i < @$rows_maker ? $rows_maker->[$i++] : undef};
    $$headers_ref //= $iterator->();
  }
  elsif (blessed $rows_maker && $rows_maker->isa('DBI::st')) {
    $rows_maker->{Executed}
      or croak '->add_sheet(..., $sth) : the statement handle must be executed (call the $sth->execute method)';
    $iterator  = sub { $rows_maker->fetchrow_arrayref};
    $$headers_ref //= $rows_maker->{NAME}; # see L<DBI>
  }
  elsif (blessed $rows_maker && $rows_maker->isa('DBIx::DataModel::Statement')) {
    DBIx::DataModel->VERSION >= 3.0
      or croak 'add_sheet(.., $statement) : requires DBIx::DataModel >= 3.0; your version is ', DBIx::DataModel->VERSION;
    $$headers_ref //= $rows_maker->sth->{NAME};
    $iterator  = sub {my $row = $rows_maker->next; return $row ? [@{$row}{@$$headers_ref}] : ()};
  }
  else {
    croak 'add_sheet() : missing or invalid last argument ($rows_maker)';
  }

  return $iterator;
}

sub _build_rows {
  my ($self, $headers, $row_iterator, $table_name) = @_;

  my $xml = "";

  # local copies for convenience
  my $date_regex = $self->{date_regex};
  my $bool_regex = $self->{bool_regex};

  # array of column references in A1 Excel notation
  my @col_letters = ('A'); # this array will be expanded on demand in the loop below

  # loop over rows and columns
  my $row_num = 0;
 ROW:
  for (my $row = $headers; $row; $row = $row_iterator->()) {
    $row_num++;
    my $last_col = @$row or next ROW;
    my @cells;

  COLUMN:
    foreach my $col (0 .. $last_col-1) {

      # if this column letter is not known yet, compute it using Perl's increment op on strings (so 'AA' comes after 'Z')
      my $col_letter = $col_letters[$col]
                   //= do {my $prev_letter = $col_letters[$col-1]; ++$prev_letter};

      # get the value; if the cell is empty, no need to write it into the XML
      my $val = $row->[$col];
      defined $val and length $val or next COLUMN;
      my $n_days; # in case we need to parse a date

      # choose XML attributes and inner value
      # NOTE : for perl, looks_like_number( "INFINITY") is TRUE! Hence the test $val !~ /^\pL/
      (                                              my $tag,  my $attrs,            $val)
      #                                                 ====   =========             ====
        = looks_like_number($val) && $val !~ /^\pL/    ? (v => ""                  , $val                           )
        : $date_regex && $val =~ $date_regex
                      && is_valid_date(\%+, \$n_days)  ? (v => qq{ s="$DATE_STYLE"}, $n_days                        )
        : $bool_regex && $val =~ $bool_regex           ? (v => qq{ t="b"}          , $1 ? 1 : 0                     )
        : $val =~ /^=/                                 ? (f => "",                   escape_formula($val)           )
        :                                                (v => qq{ t="s"}          , $self->_add_shared_string($val));

      # add the new XML cell
      my $cell = qq{<c r="$col_letter$row_num"$attrs><$tag>$val</$tag></c>};
      push @cells, $cell;
    }

    # generate the row XML and add it to the sheet
    my $row_xml = join "", qq{<row r="$row_num" spans="1:$last_col">}, @cells, qq{</row>};
    $xml .= $row_xml;
  }

  # if this sheet contains an Excel table, make sure there is at least one data row
  ++$row_num and $xml .= qq{<row r="$row_num" spans="1:1"></row>}
    if $table_name && $row_num == 1;

  return ($xml, $row_num, $col_letters[-1]);
}



sub _xml_for_options {
  my ($self, $options) = @_;

  # currently there is only one option 'cols'. Handled below in a separate sub for better clarity.
  return $self->_xml_for_cols_option($options->{cols});
}


sub _xml_for_cols_option {
  my ($self, $cols) = @_;

  my $xml = "<cols>";
  my $next_col_num = 1;
  foreach my $col (@$cols) {
    # build attributes for the node
    my %attrs = ref $col ? %$col : (width => $col); # cols => [6, ...] is just syntactic sugar for => [{witdh => 6}, ...]
    $attrs{$_} //= $next_col_num for qw/min max/;   # colrange to which this <col> specification applies
    $attrs{customWidth} //= 1 if $attrs{width};     # tells Excel that the width is not automatic

    # generate XML from attributes
    $xml .= join(" ", "<col", map {qq{$_="$attrs{$_}"}} keys %attrs) . "/>";

    # compute index of next column
    $next_col_num = $attrs{max} + 1;
  }
  $xml .= "</cols>";

  return $xml;
}


sub add_sheets_from_database {
  my ($self, $dbh, $sheet_prefix, @table_names) = &$sig_for_add_sheets_from_database;

  # in absence of table names, get them from the database metadata
  if (!@table_names) {
    my $tables = $dbh->table_info(undef, undef, undef, 'TABLE')->fetchall_arrayref({});
    @table_names = map {$_->{TABLE_NAME}} @$tables;
  }

  foreach my $table (@table_names) {
    my $sth = $dbh->prepare("select * from $table");
    $sth->execute;
    $self->add_sheet("$sheet_prefix$table", $table, $sth);
  }
}



sub _add_shared_string {
  my ($self, $string) = @_;

  # single quote before an initial equal sign is ignored (escaping the '=' like in Excel)
  $string =~ s/^'=/=/;

  # keep a global count of how many strings are in the workbook
  $self->{n_strings_in_workbook}++;

  # if that string was already stored, return its id, otherwise create a new id
  $self->{shared_strings}{$string} //= $self->{last_string_id}++;
}



sub _add_table {
  my ($self, $table_name, $last_col, $last_row, @col_names) = @_;

  # register this table
  none {$table_name eq $_} @{$self->{tables}}
    or croak "this workbook already has a table named '$table_name'";
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
  $self->add_string_to_zip(encode_utf8(join "", @xml), "xl/tables/table$table_id.xml");

  return $table_id;
}


sub add_defined_name {
  my ($self, $name, $formula, $comment) = &$sig_for_add_defined_name;

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
  my ($self, $target) = &$sig_for_save_as;

  # assemble all parts within the zip, except sheets and tables that were already added previously
  $self->add_string_to_zip($self->content_types,  "[Content_Types].xml"       );
  $self->add_string_to_zip($self->core,           "docProps/core.xml"         );
  $self->add_string_to_zip($self->app,            "docProps/app.xml"          );
  $self->add_string_to_zip($self->workbook,       "xl/workbook.xml"           );
  $self->add_string_to_zip($self->_rels,          "_rels/.rels"               );
  $self->add_string_to_zip($self->workbook_rels,  "xl/_rels/workbook.xml.rels");
  $self->add_string_to_zip($self->shared_strings, "xl/sharedStrings.xml"      );
  $self->add_string_to_zip($self->styles,         "xl/styles.xml"             );

  # write the Zip archive
  my $write_result = ref $target ? $self->{zip}->writeToFileHandle($target) : $self->{zip}->writeToFileNamed($target);
  $write_result == AZ_OK
    or croak "could not save Zip archive into " . (ref($target) || $target);
}


sub add_string_to_zip {
  my ($self, $content, $name) = @_;

  $self->{zip}->addString($content, $name, $self->{compression_level});
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


sub si_node { # build XML node for a single shared string
  my ($string) = @_;

  # escape XML entities
  $string =~ s/($entity_regex)/$entity{$1}/g;


  # Excel escapes control characters with _xHHHH_ and also escapes any
  # literal strings of that type by encoding the leading underscore. So
  # "\0" -> _x0000_ and "_x0000_" -> _x005F_x0000_.
  # The following substitutions deal with those cases.
  # This code is borrowed from Excel::Writer::XLSX::Package::SharedStrings -- thank you, John McNamara

  # Escape the escape.
  $string =~ s/(_x[0-9a-fA-F]{4}_)/_x005F$1/g;

  # Convert control character to the _xHHHH_ escape.
  $string =~ s/([\x00-\x08\x0B-\x1F])/sprintf "_x%04X_", ord($1)/eg;

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


sub is_valid_date {
  my ($named_captures, $n_days_ref) = @_;
  my ($y, $m, $d) = @{$named_captures}{qw/y m d/};

  # years before 1900 can't be handled by Excel
  return undef if $y < 1900;

  # convert the given date into a number of days since 1st January 1900.
  my $return_status = try   {$$n_days_ref = Delta_Days(1900, 1, 1, $y, $m, $d) + 1;
                             my $is_after_february_1900 = $$n_days_ref > 59;
                             $$n_days_ref += 1 if $is_after_february_1900; # because Excel wrongly treats 1900 as a leap year
                             1; # success
                            };
                             # no catch .. undef if failure (invalid date)
 
  return $return_status;

  # NOTE : invalid dates will be inserted as Excel strings
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
  $writer->add_sheet($sheet_name2, $table_name2, \@headers, sub {...});
  $writer->add_sheet($sheet_name3, $table_name3, $sth);       # DBI statement handle
  $writer->add_sheet($sheet_name4, $table_name4, $statement); # DBIx::DataModel::Statement object
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
in C<< $+{d} >>, C<< $+{m} >> and C<< $+{y} >>. If this parameter receives C<undef>,
no date handling will be performed.

=item bool_regex

A compiled regular expression for detecting data cells that contain boolean values.
The default implementation recognizes uppercase strings 'TRUE' or 'FALSE' as booleans.
User-supplied regular expressions should put the word corresponding to 'TRUE' within
parenthesis so that the content is captured in C<$1>. Here is an example for french :

  $writer = Excel::ValueWriter::XLSX->new(bool_regex => qr[^(?:(VRAI)|FAUX)$]);

If this parameter receives C<undef>, no bool handling will be performed.


=item compression_level

A number from 0 (no compression) to 9 (maximum compression) specifying
the desired ZIP compression level. High values produce smaller files but
consume more CPU. The default is taken from COMPRESSION_LEVEL_DEFAULT in
L<Archive::Zip>, which amounts to 6.

=back

=head2 add_sheet

  $writer->add_sheet($sheet_name, $table_name[, $headers], $rows_maker[, \%options]);

Adds a new worksheet into the workbook.

=over

=item *

The C<$sheet_name> is mandatory; it must be unique and between 1 and 31 characters long.

=item *

If C<$table_name> is not C<undef>, the sheet contents will be registered as an
L<Excel table|https://support.microsoft.com/en-us/office/overview-of-excel-tables-7ab0bb7d-3a9e-4b56-a3c9-6c94334e492c> 
of that name. Excel tables offer more features than regular ranges of cells,
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
row produced by C<$rows_maker> will be treated as headers.


=item *

The C<$rows_maker> argument may be:

=over

=item *

a reference to a 2-dimensional array of values

=item *

a reference to a callback function that will return a new row at each call, in the
form of a 1-dimensional array reference. An empty return from the callback
function signals the end of data (but intermediate empty rows may be returned
as C<< [] >>). Callback functions should typically be I<closures> over a lexical
variable used to decide when the last row has been met. Here is an example of a
callback function used to feed a sheet with 500 lines of 300 columns of random numbers:

  my @headers_for_rand = map {"h$_"} 1 .. 300;
  my $random_rows = do {my $count = 500; sub {$count-- > 0 ? [map {rand()} 1 .. 300] : undef}};
  $writer->add_sheet(RAND_SHEET => rand => \@headers_for_rand, $random_rows);

=item *

an executed L<DBI> statement handle

=item *

a L<DBIx::DataModel::Statement> object (version 3.0 or greater)

=back

=item *

C<< \%options >> is an optional reference to a hash of additional options.
Currently the only option is C<cols>, which points to an arrayref of column specifications.
The arrayref may contain :

=over

=item *

a list of numbers specifying the width of successive columns, like for example :

  $writer->add_sheet(S_sales => sales => [qw/date product_id descr price/], $rows, {cols => [12, 8, 20, 8]);

Column widths in Excel are expressed in "character units", i.e. a requested width of 8 should
be just wide enough to display the string '00000000' (8 zero characters displayed with the normal font).

=item *

a list of hashrefs specifying column attributes. The C<width> attribute corresponds to column widths,
as explained above. The C<style> attribute is a numeric index into the list of styles defined within
the workbook -- except that currently this module only supports one single style for dates, so this
addition has no practical use at the moment.

=back


=back

Cells within a row must contain scalar values. Values that look like numbers are treated
as numbers. String values that match the C<date_regex> are converted into numbers and
displayed through a date format, but only if the date is valid and is above 1900 January 1st --
otherwise it is treated as a string, like in Excel.
String values that start with an initial '=' are treated
as formulas; but like in Excel, if you want a plain string that starts with a '=', put a single
quote just before the '=' -- that single quote will be removed from the string.
Everything else is treated as a string. Strings are shared at the workbook level
(hence a string that appears several times in the input data will be stored
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
