package Lingua::FR::Ladl::Table;

use warnings;
use strict;
use English;

use version; our $VERSION = qv('0.0.1');

use Carp;

use Readonly;
use List::Util qw(max first);
use List::MoreUtils qw(all);


use Lingua::FR::Ladl::Exceptions;
use Lingua::FR::Ladl::Parametrizer;
use Lingua::FR::Ladl::Util;

use Class::Std;

{
  Readonly my %is_implemented_format => ( xls => \&_load_xls,
                                          xml => \&_load_gnumeric_xml );

  my %name_of : ATTR( :default('none') :name<name>);
  my %table_of : ATTR;   # hash of hashes to hold the table data in a perl data structure
  my %maxCol_of : ATTR( :default(0) :name<maxCol>);
  my %maxRow_of : ATTR( :default(0) :name<maxRow>);
  my %verbCol_of : ATTR;
  my %verbs_of : ATTR;
  my %colTypes_of : ATTR;
  my %is_tildaRow_of : ATTR;
  my %headers_of : ATTR;
  my %parameters_of : ATTR( :set<parameters> :get<parameters> ); # customization parameters

  ############# Utility subroutines #################################################################
  
  sub _find_out_verbCol {
    my ($id) = @_;

    my $name = $name_of{$id};
    
    my $verbCol = first { $table_of{$id}->{0}->{$_} =~ m{\b$name\b} } (keys %{$table_of{$id}->{0}});

    if ($verbCol) {
      $verbCol_of{$id} = $verbCol;
      return $verbCol_of{$id};
    } else {
      carp "Couldn't find out verb column: no column with column header $name\n";
      return;
    }
    
  }

  sub _check_row {
    my ($table, $row, $message) = @_;

    croak "$row must be greater 0\n" unless $row;

    my $id = ident $table;
    X::NoTableData->throw(
                          message => $message,
                          table => $table,
                         ) unless $table_of{$id};

    croak "$row must be less or equal $maxRow_of{$id}\n" if $row > $maxRow_of{$id};

    return;

  }

    sub _check_col {
    my ($table, $col, $message) = @_;

    croak "$col must be greater 0\n" unless $col;

    my $id = ident $table;
    X::NoTableData->throw(
                          message => $message,
                          table => $table,
                         ) unless $table_of{$id};

    croak "$col must be less or equal $maxCol_of{$id}\n" if $col > $maxCol_of{$id};

    return;

  }

  sub _load_xls {
    my ($file_name) = @_;

    my $table_ref = {};
    
    eval { use Spreadsheet::ParseExcel; };
    if ($EVAL_ERROR) {
      croak "Can't load table data from excel file $file_name: Spreadsheed::ParseExcel not installed";
    }
    
    my $excel = Spreadsheet::ParseExcel::Workbook->Parse($file_name) or
      croak "Error parsing $file_name: Spreadsheet::ParseExcel returned undef\n";
    my $sheet = $excel->{Worksheet}->[0];
    $sheet->{MaxRow} ||= $sheet->{MinRow};
    unless ($sheet->{MaxRow}) {
      croak "Couldn't load table data: Spreadsheet::ParseExcel returned 0 max row when parsing $file_name\n";
    }
    foreach my $row ($sheet->{MinRow} .. $sheet->{MaxRow}) {
      $sheet->{MaxCol} ||= $sheet->{MinCol};
      foreach my $col ($sheet->{MinCol} ..  $sheet->{MaxCol}) {
        my $cell = $sheet->{Cells}[$row][$col];
        if ($cell) {
          $table_ref->{$row}->{$col} = $cell->{Val};
        }
      }
    }
    return ($table_ref, $sheet->{MaxRow}, $sheet->{MaxCol});
  }


  sub _load_gnumeric_xml {
    my ($file_name) = @_;

    my $table_ref = {};

    eval { use XML::LibXML; };
    if ($EVAL_ERROR) {
      croak "Can't load table data from xml file $file_name: XML::LibXML not installed\n";
    }

    
    my $parser = XML::LibXML->new();
    $parser->keep_blanks(0);
    my $table_doc = $parser->parse_file($file_name);
    my @cells = $table_doc->findnodes("//gmr:Cell");
    foreach my $cell (@cells) {
      my $row = $cell->getAttribute('Row');
      my $col = $cell->getAttribute('Col');
      $table_ref->{$row}->{$col}=$cell->textContent();
    }
    my @maxRowCells = $table_doc->findnodes("//gmr:MaxRow");
    my $maxRow = $maxRowCells[0]->textContent();

    my @column_nbrs = map { $_->getValue() } $table_doc->findnodes('//gmr:Cell/@Col');
    
    my $maxCol = max @column_nbrs;

    return ($table_ref, $maxRow, $maxCol);
    
  }

  ############ Methods ###################################################################

  sub BUILD {
    my ($self, $id, $arg_ref) = @_;

    # parametrize with new default parametrizer
    my $param = Lingua::FR::Ladl::Parametrizer->new();
    $parameters_of{$id} = $param;
  }
  
  sub load {
    my ($self, $arg_ref) = @_;
    my $format = $arg_ref->{format};
    my $file_name = $arg_ref->{file};
    my $id = ident $self;

    unless ($is_implemented_format{$format}) {
      croak 'Format must be one of '.join(', ', keys %is_implemented_format).", not $format\n";
    }

=for Rationale:
     We set a default table name, inferred from the file name.
     The table name is needed for inferring the verb column
     which is the header of the verb column.
     However the table name can be also set manually.
     The get_verb_column() method won't work if the table name is
     not set correctly.

=cut

    $self->set_name(_Name::from_file_name($file_name));

    ($table_of{$id}, $maxRow_of{$id}, $maxCol_of{$id}) = $is_implemented_format{$format}->($file_name);
    
    return;
  }


=for Rationale
     The header line is line number 0 in the table
     This sub returns a hash with the headers as keys and the columns as values.

=cut
  
  sub get_headers {
    my ($self) = @_;
    my $id = ident $self;

    if ($headers_of{$id}) {
      return $headers_of{$id};
    }
    
    X::NoTableData->throw(
                          message => "Could not get table headers:\n",
                          table => $self)
        unless $table_of{$id};

    foreach my $col_num (0..$maxCol_of{$id}) {
      if (exists $table_of{$id}->{0}->{$col_num}) {
        my $header = $table_of{$id}->{0}->{$col_num};
        $headers_of{$id}->{$header} = $col_num;
      } else {
        $headers_of{$col_num} = $col_num;
      }
    }
    
    return $headers_of{$id};
  }

  sub get_value_at {
    my ($self, $row, $col) = @_;
    my $id = ident($self);

    _check_row($self, $row, "Can't get value at $row, $col:");
    _check_col($self, $col, "Can't get value at $row, $col:");

    return $table_of{$id}->{$row}->{$col};
  }

  sub get_col_for_header {
    my ($self, $header) = @_;
    my $id = ident($self);

    X::NoTableData->throw(
                          message => "Couldn't find out col for header:\n",
                          table => $self )
        unless $table_of{$id};

    my $col_for_headers = $self->get_headers();
    if (exists($col_for_headers->{$header})) {
      return $col_for_headers->{$header};
    } else {
      return;
    }

  }

  sub get_header_for_col {
    my ($self, $col) = @_;
    my $id = ident($self);

    _check_col($self, $col, "Can't get header for $col:");

    my $header = $table_of{$id}->{0}->{$col};
    my $empty_string_mark = $self->get_parameters()->get_empty_string_mark();
    $header =~ s{$empty_string_mark}{};
    return $header;
  }


=for Rationale:
     we determine the verb column as the header column with the table name
     this is an empirical observation, it may fail!

=cut

  sub get_verb_column {
    my ($self) = @_;
    my $id = ident $self;
    
    if ($verbCol_of{$id}) {
      return $verbCol_of{$id};
    } else {
      X::NoTableData->throw(
                            message => "Couldn't find out verb column:\n",
                            table => $self )
          unless $table_of{$id};
      return _find_out_verbCol($id);
    }
  }



  sub get_verbs {
    my ($self) = @_;
    my $id = ident $self;

    if ($verbs_of{$id}) {
      return @{$verbs_of{$id}};
    } else {
      croak "Need table to calculate verbs\n" unless $table_of{$id};
      my $verbCol = $verbCol_of{$id} or $self->get_verb_column();
      my $maxRow = $maxRow_of{$id} or $self->get_maxRow();
      croak "Max row must be greater 0" unless $maxRow;
      $verbs_of{$id} = [ map { $table_of{$id}->{$_}->{$verbCol} } 1 .. $maxRow ];
      return @{$verbs_of{$id}};
    }
  }


=for Rationale:
     the particle column is the column before the verb column

=cut

  sub get_particle_column {
    my ($self) = @_;
    my $id = ident $self;

    my $verbCol = $verbCol_of{$id} or $self->get_verb_column();

    return $verbCol - 1;
    
  }

=for Rationale:
     the example column is the last column

=cut

  sub get_example_column {
    my ($self) = @_;
    my $id = ident $self;

    if ($maxCol_of{$id}) {
      return $maxCol_of{$id};
    } else {
      X::NoTableData->throw(
                            message => "Max column is 0!\n",
                            table => $self,
                           );
      return;
    }
  }

=for Rationale:
  We try to determine the data type of a specific column
  first we read a sample row (other than 0 which is the header row)
  if the content of a given column is other than '+' '-' '~' we 
  presume that this column is supposed to contain text data,
  else the possible values are '+', '-', '~'
  Returns a hash reference with the column index as keys and either the string `+-~' or the string `text' as values.

=cut

  sub get_column_types {
    my ($self) = @_;
    my $id = ident $self;
    
    if ($colTypes_of{$id}) {
      return $colTypes_of{$id};
    } else {
      
      X::NoTableData->throw(
                            message => "Couldn't calculate column types:\n",
                            table => $self,
                           )
          unless $table_of{$id};
      
      while ( my ($col_num, $col_val) = each %{$table_of{$id}->{1}} ) {
        if ( $col_val =~ m{\A \s* [+-~] \s* \z}xms ) {
          $colTypes_of{$id}->{$col_num} = '+-~';
        } else {
          $colTypes_of{$id}->{$col_num} = 'text';
        }
      }
      return $colTypes_of{$id};
    }
  }

  sub get_column_type_for_col {
    my ($self, $col) = @_;
    my $id = ident $self;

    _check_col($self, $col, "Can't get column type for column $col:");

    my $colTypes = $colTypes_of{$id} ? $colTypes_of{$id} : $self->get_column_types();

    return $colTypes->{$col};
  }

  

=for Rationale:
     A row of the table is a tilda row when all the columns of `+-~'
     type contain a `~'. This means, the table doesn't say anything about this verb (usage). 
     The row is identified by number.

=cut

  sub is_tilda_row {
    my ($self, $row) = @_;
    my $id = ident $self;

    if ($is_tildaRow_of{$id}) {
      return $is_tildaRow_of{$id};
    }
    
    my $err_msg = "Can't check if tilda row: \n";
    _check_row($self, $row, $err_msg);

    my $col_types = $self->get_column_types();

    $is_tildaRow_of{$id} = all { $table_of{$id}->{$row}->{$_} eq '~' } grep { $col_types->{$_} eq '+-~' } keys %{$col_types};
    
    return $is_tildaRow_of{$id};
  }

  sub get_verb_for_row {

    my ($self, $row) = @_;
    my $id = ident $self;

    my $err_msg = "Can't get verb of row:\n";
    _check_row($self, $row, $err_msg);

    return $table_of{$id}->{$row}->{$verbCol_of{$id}};
  }

  sub get_rows_for_verb {
    my ($self, $verb) = @_;
    my $id = ident $self;

    croak "No verb\n" unless $verb;

    X::NoTableData->throw(
                          message => "Couldn't get rows of verb: $verb:\n",
                          table => $self,
                         ) unless $table_of{$id};

    my $verbCol = $verbCol_of{$id};
    my @rows = grep { $table_of{$id}->{$_}->{$verbCol} =~ m{\b$verb\b} } 1 .. $maxRow_of{$id};

    return (@rows);
  }


=for Rationale:
     A column may be of type `text' or `+-~'.
     - A `text' column of a row is set if it's different from the `Empty mark', which in this case is <E>.
     - A `+-~' column of a row is set if it's `+'.
     The `empty string mark' can be set via the Parametrizer Object

=cut

  
  sub is_column_set {
    my ($self, $row, $col) = @_;

    _check_row($self, $row, "Can't test if column is set:\n");
    my $col_types = $self->get_column_types();
    my $empty_mark = $self->get_parameters()->get_empty_string_mark();
    my $re = qr($empty_mark);
    
    if ($col_types->{$col} eq 'text') {
      $table_of{ident $self}->{$row}->{$col} =~ m{$re} ? return 0 : return 1;
    } else {
      $table_of{ident $self}->{$row}->{$col} =~ m{[+]} ? return 1 : return 0;
    }
  }

  sub has_verb {
    my ($self, $verb) = @_;
    my $id = ident($self);
    
    croak "Can't check on empty verb\n" unless $verb;

    my $verbCol = $self->get_verb_column();

    return grep { m{\b$verb\b} } map { $table_of{$id}->{$_}->{$verbCol}  } 1 .. $maxCol_of{$id};
  }

  sub has_verb_matching {
    my ($self, $match) = @_; # match is supposed to be a pattern: either a string or a qr//
    my $id = ident($self);

    croak "Won't check on empty match\n" unless $match;

    my $verbCol = $self->get_verb_column();

    return grep { m{$match} } map { $table_of{$id}->{$_}->{$verbCol}  } 1 .. $maxCol_of{$id};
  }

  sub create_db_table {
    my ($self, $arg_ref) = @_;
    my $id = ident($self);

    X::NoTableData->throw(
                          message => "Can't create DB handle:\n",
                          table => $self,
                         ) unless $table_of{$id};

    use DBI;
    my $dbh=DBI->connect('dbi:AnyData(RaiseError=>1):');
    
    my @column_names;
    if (not ($arg_ref) or $arg_ref->{col_names} eq 'col_numbers') {
      @column_names = map { "col_$_" } 0 .. $maxCol_of{$id};
    } else {
      @column_names =
        map {
          my $header = $table_of{$id}->{0}->{$_};
          if (not $header) {
            $header = "col_$_";
          }
          $header =~ m{\A \p{Alphabetic} }x ? $header : "col_$header";
        } 0 .. $maxCol_of{$id};
      my $verbCol = $verbCol_of{$id} or $self->get_verb_column();
      $column_names[$verbCol] = 'verb';
      $column_names[$verbCol-1] = 'particle';
      $column_names[$maxCol_of{$id}] = 'example';
    }

    my $empty_string_mark = $parameters_of{$id}->get_empty_string_mark();
    my $db_array_ref = [
                        [@column_names],
                        map {
                          my $row = $_;
                          [
                           map {
                             my $col_value = $table_of{$id}->{$row}->{$_};
                             $col_value =~ s{$empty_string_mark}{};
                             "$col_value";
                           } 0 .. $maxCol_of{$id}
                          ];
                        } 1 .. $maxRow_of{$id}
                       ];
    
    $dbh->func( "table_$name_of{$id}",
                'ARRAY',
                $db_array_ref,
                'ad_import');

    return $dbh;
  }
  
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Lingua::FR::Ladl::Table - An object representing a Ladl Table


=head1 VERSION

This document describes Lingua::FR::Ladl::Table version 0.0.1


=head1 SYNOPSIS

    use Lingua::FR::Ladl::Table;

    my $table = Lingua::FR::Ladl::Table->new({ name => $table_ref->{name} });

    # load table data from an excel file:
    $table->load({ format => 'xls', file => 't/1.xls' }); 

    # load table data from a gnumeric xml file:
    $table->load({ format => 'xml', file => 't/1.xml' }); 

    $table->set_name('1'); 
    my $name = $table->get_name();

    my $verbCol = $table->get_verb_column();  # which column contains the verb

    my $col = $table->get_col_for_header('aux =: avoir'); # which column's header is 'aux =: avoir'?

    my $header = $table->get_header_for_col(4); # what is the column header of column 4?

    my $dbh = $table->create_db_table( { col_names => 'col_numbers' } ); # get a db handle with column numbers as column names

    # Query the table using SQL::Statement: for which verbs is column 8 empty and column 19 = '+'?
    my $query = "SELECT col_$verbCol FROM table_$name where col_8 = NULL AND col_19 = '+'";
    my $sth = $dbh->prepare($query);
    $sth->execute();



=head1 DESCRIPTION

This module provides a data structure representing a Ladl table. The Ladl tables are the digitized representation of Maurice Gross's B<Grammar Lexicon>, a very large scale, high precision, French linguistic resource, developed over several years by a group of skilled linguists and according to well defined linguistic criteria. The grammar lexicon describes syntactic and semantic properties of French (basic) sentences.

A B<table> gathers together predicative items (verbs in this case) with comparable syntactico-semantic behaviour.

In a table, B<columns> further specify the syntactico-semantic properties of each verb in that table.

=head2 Example

=begin HTML

<TABLE border=1>
<CAPTION>1</CAPTION>
<TR>
<TD  valign="bottom"  align="left" >N0 =: Nhum</TD>
<TD COLSPAN=2  valign="bottom"  align="left" >N0 =: Nnc</TD>
<TD  valign="middle"  align="center" >1</TD>
<TD  valign="bottom"  align="left" >aux =: avoir</TD>
<TD  valign="bottom"  align="left" >aux =: &#234;tre</TD>
<TD  valign="bottom"  align="left" >N0 est Upp W</TD>
<TD COLSPAN=2  valign="bottom"  align="left" >N0 U</TD>
<TD  valign="bottom"  align="left" >N1 =: Qu P</TD>
<TD  valign="bottom"  align="left" >N1 =: Qu Psubj</TD>
<TD  valign="bottom"  align="left" >Tp = Tc</TD>
<TD  valign="bottom"  align="left" >Tc =: pass&#233;</TD>
<TD  valign="bottom"  align="left" >Tc =: pr&#233;sent</TD>
<TD  valign="bottom"  align="left" >Tc =: futur</TD>
<TD  valign="bottom"  align="left" >Vc =: devoir</TD>
<TD  valign="bottom"  align="left" >Vc =: pouvoir</TD>
<TD  valign="bottom"  align="left" >Vc =: savoir</TD>
<TD  valign="bottom"  align="left" >V-inf0 W = Ppv</TD>
<TD  valign="bottom"  align="left" >N0 U Pr&#233;p N1</TD>
<TD  valign="bottom"  align="left" >N0 U Pr&#233;p Nhum</TD>
<TD  valign="bottom"  align="left" >N0 U Pr&#233;p N-hum</TD>
<TD  valign="bottom"  align="left" >Pr&#233;p N1 = Ppv</TD>
<TD  valign="bottom"  align="left" >N0 U dans N1</TD>
<TD  valign="bottom"  align="left" >N0 U N1</TD>
<TD  valign="bottom"  align="left" >N0 U Nhum</TD>
<TD COLSPAN=2  valign="bottom"  align="left" >N0 U N-hum</TD>
</TR>
<TR>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >&lt;E&gt;</TD>
<TD  valign="bottom"  align="left" >achever</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >de</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >Max ach&#232;ve de peindre le mur</TD>
</TR>
<TR>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >&lt;E&gt;</TD>
<TD  valign="bottom"  align="left" >aller</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >&lt;E&gt;</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >Max va partir</TD>
</TR>
<TR>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >&lt;E&gt;</TD>
<TD  valign="bottom"  align="left" >aller</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >jusqu'&#224;</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >La pluie va tomber</TD>
</TR>
<TR>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >ne</TD>
<TD  valign="bottom"  align="left" >aller N&#233;g</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >sans</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >+</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >-</TD>
<TD  valign="bottom"  align="left" >Cette mesure n'ira pas sans cr&#233;er des troubles</TD>
</TR>
</TABLE>

=end HTML

The tables are available as a set of excel spreadsheets from L<http://ladl.univ-mlv.fr/>

This module represents a table as a Ladl::Table object and allows to investigate and query:

=over

=item what verbs belong to the table.

=item what are the headers of the table?

=item which column corresponds to which header.

=item which verb corresponds to which row(s).

=item what is the value of a column in a given row.

=item what is the value in a given row for a given header.

=back

It is also possible to formulate more complex queries using the SQL dialect implemented in SQL::Statement (see L<SQL::Statement>).

=head1 INTERFACE 

=head2 Methods

For all following methods, column and row numbering starts at 0.

=over

=item new - build a new Table object

  my $table = Lingua::FR::Ladl::Table->new({ name => 'test_table' });

There's one optional initial argument: I<name>, the table's name

=item set/get_name

=item load

  $table->load( {format => 'xls', file=>'file_name'} )

  $table->load( {format => 'xml', file=>'file_name'} )

Load table data from a file in the given format.
Format may be one of:

=over

=item xls - file is an excel file

in this case Spreadsheet::Parser is used to parse the file.

=item xml - an xml file in gnumeric xml format

the file is parsed using XML::LibXML

=back

The file name is also set to a value inferred from the file name by removing the suffix.
The file name is important because the B<get_verb_column> method relies on the correct file name.

=item get/set_maxCol, get/set_maxRow

get/set maximum row or column value


=item get_headers

Return a hash with the column headers as keys and the corresponding column numbers as values. When there's no header, I<col_>column number is used as key.

=item get_value_at($row, $col)

=item get_col_for_header( $header )

return column number for a given column header, undef if $header doesn't match.
For the table in the example:

  $table->get_col_for_header('aux =: avoir')

  returns 4


=item get_header_for_col($col)

return the header for a given column.

Example:

  $table->get_header_for_col(4)

  returns 'aux =: avoir'


=item get_verb_column

return the column (by number) containing the verb.
The verb column is assumed to be the column the header of which is equal to the table name.

For the table in the example

  $table->get_verb_column();

  returns 3

=item get_verbs

return the list of verbs of the table (as an array).

=item get_particle_column

The particle column contains entries as I<ne>, I<n'>, I<se>, I<s'>, occuring in front of the verb.
We assume it to be the column right before the verb column.

Example:

  $table->get_particle_column()

  returns 2

=item get_example_column

The example column contains example phrases with the verb of the row. We assume it's the last column of the table.

For the table in the example above:

  my $col = $table->get_example_column()

would set I<$col> to I<28>


=item get_column_types

Columns may either contain text or one of '+', '-' and '~'. The method returns a reference to a hash with the column numbers as keys and assigning to the columns either 'text' if they have text content or else '+-~'.

For the table in the example:

  $table->get_column_types()

returns the hash:

  {
                '0' => '+-~',
                '1' => '+-~',
                '2' => 'text',
                '3' => 'text',
                '4' => '+-~',
                '5' => '+-~'
                '6' => '+-~',
                '7' => '+-~',
                '8' => 'text',
                '9' => '+-~',
                '10' => '+-~',
                '11' => '+-~',
                '12' => '+-~',
                '13' => '+-~',
                '14' => '+-~',
                '15' => '+-~',
                '16' => '+-~',
                '17' => '+-~',
                '18' => '+-~',
                '19' => '+-~',
                '20' => '+-~',
                '21' => '+-~',
                '22' => '+-~',
                '23' => '+-~',
                '24' => '+-~',
                '25' => '+-~',
                '26' => '+-~',
                '27' => 'text',
  };

=item get_column_type_for_col

Return the column type for a given column. The column type is either I<+-~> if the columns contains only one of `+', `-' or `~', or I<text> if the column contains some other text content.

Throws an exception when column is inexistant.

Example:

   $table->get_column_type_for_col(2)

   returns `text';


=item is_tilda_row($row)

A row is a tilda row if all the columns of type '+-~' are '~' - i.e. they contain no specific information about this verb.

=item get_verb_for_row($row)

Return the verb for a given row.
For the the table in the example above:

  my $verb = $table->get_verb_for_row(3)

  returns `aller'

=item get_rows_for_verb($verb)

Returns the rows the verb occurs in (there may be more than 1).
Example:

  my @rows = $table->get_rows_for_verb('devoir');

  @rows is (27, 28, 29)


=item is_column_set($row, $col)

A column may be of type I<text> or I<+-~>.

=over

=item a I<text> column of a row is set if it's different from the `Empty mark', which by default is <E>.

=item a I<+-~> column of a row is set if it's I<+>.

=back

The I<empty_string_mark> can be set via the L</Parameters> accessors.

=item has_verb($verb)

Returns I<true> if the verb is contained in the table.

=item has_verb_matching($regexp)

Returns I<true> if a verb of the table matches $regexp.

=item create_db_table( { col_names => 'col_numbers' } )

Provides a DB interface using DBI and returns a db handle to an in-memory table created using DBD::AnyData. The table name is I<table_>$table_name. The column names are either

=over

=item I<col_>$col_numbers,

when the argument is { col_names => 'col_numbers' } (the default).

=item The column headers

when another argument is given. When the header is empty col_I<column_number> is used.

=back

Example:

   # get a db handle with columns named col_<column number>
   # default: { col_names => 'col_numbers' }
   my $dbh = $table->create_db_table();

   # get a db handle using the column headers as column names
   $dbh = $table->create_db_table( { col_names => 'headers' } );


Once you have a db handle you can start querying the table using SQL::Statement (see L<SQL::Statements> and L<DBD::AnyData> for which SQL statements are supported).

Example:

    my $query = "SELECT col_$verbCol FROM table_$name where col_8 = NULL AND col_19 = '+'";
    my $sth = $dbh->prepare($query);
    $sth->execute();


Note: The empty string marks (`<E>' by default) are replaced by empty strings, equivalent to NULL.

=back

=head2 Parameters

The class is parametrized by a Parametrizer (see L<Lingua::FR::Ladl::Parametrizer>) object, which can be accessed by the get/set_parameters method. A parametrizer object provides accessors for its customization items. Currently the most important item is the I<empty_string_mark> which defaults to `<E>'. You could change the I<empty_string_mark> like so:

  my $par_object = $table->get_parameters();
  $par_object->set_empty_string_mark('EMPTY');
  $table->set_parameters($par_object);


=head1 DIAGNOSTICS

=over

=item C<< Format must be one of xls, xml not $format >>

Exception thrown when trying to load the table from a format that is not supported currently.

The only supported formats are:

=over

=item xls

excel table

=item xml

gnumeric xml format

=back

=item C<< Could not create file parser context for file "unknown" >>

Thrown by LibXML, the xml parser: Ladl::Table wants to load table data by parsing an xml file,
but the xml parser throws an exception. Maybe the file is not accessible?

=item C<< Couldn't load table data: error parsing file >>

Ladl::Table wants to load table data by parsing an excel file, but Spreadsheet::ParseExcel returned invalid data.
Maybe the file is not accessible?

=item C<< Need table data for table_name, maybe you should call the load method first? >>

Most methods only work and make sense if table data is loaded.

=item C<< col/row must be less or equal max_row/max_col >>

Method was called with an invalid row/column respectively.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Lingua::FR::Ladl::Table requires no configuration files or environment variables.


=head1 DEPENDENCIES

=over

=item L<Class::Std>

=item L<Readonly>

=item L<List::Util>

=item L<List::MoreUtils>

=item L<XML::LibXML>

if you want to load table data from a gnumeric XML file.

=item L<Spreadsheet::ParseExcel>

if you want to load table data from an excel file.

=item L<DBI> and L<DBD::AnyData> 

if you want to use a DB interface.

=back

=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.

=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-lingua-fr-ladl-table@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<http://ladl.univ-mlv.fr/>, where the Ladl tables have been developed and where they can be obtained.

Some publications on this project:

=over

=item B<Maurice Gross' grammar lexicon and Natural Language Processing>

by Claire Gardent, Bruno Guillaume, Guy Perrier, Ingrid Falk

L<http://hal.archives-ouvertes.fr/action/open_file.php?url=http://hal.archives-ouvertes.fr/docs/00/10/31/56/PDF/poznan05.pdf&docid=103156>

=item B<Extracting subcategorisation information from Maurice Gross' grammar lexicon>,

by Claire Gardent, Bruno Guillaume, Guy Perrier, Ingrid Falk
in Archives of Control Sciences (2005) 289--300

=item A talk at the French Perl Workshop 2006 (in French ;-)

L<http://conferences.mongueurs.net/fpw2006/slides/lexique-syntaxique.pdf>

=back


=head1 AUTHOR

Ingrid Falk  C<< <ingrid dot falk at loria dot fr> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Ingrid Falk C<< <ingrid dot falk at loria dot fr> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
