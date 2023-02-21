package Excel::ValueReader::XLSX::Backend::Regex;
use utf8;
use 5.10.1;
use Moose;
use Scalar::Util qw/looks_like_number/;
use Carp         qw/croak/;

extends 'Excel::ValueReader::XLSX::Backend';

our $VERSION = '1.10';

#======================================================================
# LAZY ATTRIBUTE CONSTRUCTORS
#======================================================================

sub _strings {
  my $self = shift;
  my @strings;

  # read from the sharedStrings zip member
  my $contents = $self->_zip_member_contents('xl/sharedStrings.xml');

  # iterate on <si> nodes
  while ($contents =~ m[<si>(.*?)</si>]sg) {
    my $innerXML = $1;

    # concatenate contents from all <t> nodes (usually there is only 1) and decode XML entities
    my $string = join "", ($innerXML =~ m[<t[^>]*>(.+?)</t>]sg);
    _decode_xml_entities($string);

    push @strings, $string;
  }

  return \@strings;
}


sub _workbook_data {
  my $self = shift;

  # read from the workbook.xml zip member
  my $workbook = $self->_zip_member_contents('xl/workbook.xml');

  # extract sheet names
  my @sheet_names = ($workbook =~ m[<sheet name="(.+?)"]g);
  my %sheets      = map {$sheet_names[$_] => $_+1} 0 .. $#sheet_names;

  # does this workbook use the 1904 calendar ?
  my ($date1904) = $workbook =~ m[date1904="(.+?)"];
  my $base_year  = $date1904 && $date1904 =~ /^(1|true)$/ ? 1904 : 1900;

  return {sheets => \%sheets, base_year => $base_year};
}



sub _date_styles {
  my $self = shift;

  state $date_style_regex = qr{[dy]|\bmm\b};

  # read from the styles.xml zip member
  my $styles = $self->_zip_member_contents('xl/styles.xml');

  # start with Excel builtin number formats for dates and times
  my @numFmt = $self->Excel_builtin_date_formats;

  # add other date formats explicitly specified in this workbook
  while ($styles =~ m[<numFmt numFmtId="(\d+)" formatCode="([^"]+)"/>]g) {
    my ($id, $code) = ($1, $2);
    $numFmt[$id] = $code if $code =~ $date_style_regex;
  }

  # read all cell formats, just rembember those that involve a date number format
  my ($cellXfs)    = ($styles =~ m[<cellXfs count="\d+">(.+?)</cellXfs>]);
  my @cell_formats = $self->_extract_xf($cellXfs);
  my @date_styles  = map {$numFmt[$_->{numFmtId}]} @cell_formats;

  return \@date_styles; # array of shape (xf_index => numFmt_code)
}


sub _extract_xf {
  my ($self, $xml) = @_;

  state $xf_node_regex = qr{
   <xf                  # initial format tag
     \s
     ([^>/]*+)          # attributes (captured in $1)
     (?:                # non-capturing group for an alternation :
        />              # .. either an xml closing without content
      |                 # or
        >               # .. closing for the xf tag
        .*?             # .. then some formatting content
       </xf>            # .. then the ending tag for the xf node
     )
    }x;

  my @xf_nodes;
  while ($xml =~ /$xf_node_regex/g) {
    my $all_attrs = $1;
    my %attr;
    while ($all_attrs =~ m[(\w+)="(.+?)"]g) {
      $attr{$1} = $2;
    }
    push @xf_nodes, \%attr;
  }
  return @xf_nodes;
}


#======================================================================
# METHODS
#======================================================================

sub values {
  my ($self, $sheet) = @_;
  my @data;
  my ($cell_type, $seen_node);

  # regexes for extracting information from cell nodes
  state $row_regex = qr(
     <(row)                  # row tag ($1)
       (?:\s+r="(\d+)")?     # optional row number ($2)
       [^>/]*?               # unused attrs
     >                       # end of tag
    )x;
  state $cell_regex = qr(
     <(c)                    # cell tag ($3)
      (?: \s+ | (?=>) )      # either a space before attrs, or end of tag
      (?:r="([A-Z]+)(\d+)")? # capture col ($4) and row ($5)
      [^>/]*?                # unused attrs
      (?:s="(\d+)"\s*)?      # style attribute ($6)
      (?:t="(\w+)"\s*)?      # type attribute ($7)
     (?:                     # non-capturing group for an alternation :
        />                   # .. either an xml closing without content
      |                      # or
        >                    # .. closing xml tag, followed by
      (?:

         <v>(.+?)</v>        #    .. a value ($8)
        |                    #    or 
          (.+?)              #    .. some node content ($9)
       )
       </c>                  #    followed by a closing cell tag
      )
    )x;
  state $row_or_cell_regex = qr($row_regex|$cell_regex);
  # NOTE : these regexes uses positional capturing groups; it would be more readable with named
  # captures instead, but it doubles the execution time on big Excel files, so I
  # stick to plain old capturing groups.

  # does this instance want date formatting ?
  my $has_date_formatter = $self->frontend->date_formatter;

  # parse worksheet XML, gathering all cells
  my $contents = $self->_zip_member_contents($self->_zip_member_name_for_sheet($sheet));

  # loop on matching nodes
  my ($row, $col) = (0, 0);
  while ($contents =~ /$row_or_cell_regex/g) {
    if ($1) {                # this is a 'row' tag
      $row = $2 // $row+1;
      $col = 0;
    }
    elsif ($3) {             # this is a 'c' tag
      my ($col_A1, $given_row, $style, $cell_type, $val, $inner) = ($4, $5, $6, $7, $8, $9);

      # row and column for this cell -- either given, or incremented from last cell
      ($col, $row) = $col_A1 && $given_row ? ($self->A1_to_num($col_A1), $given_row)
                                           : ($col+1,                    $row);

      # handle cell value according to cell type
      $cell_type //= '';
      if ($cell_type eq 'inlineStr') {
        # this is an inline string; gather all <t> nodes within the cell node
        $val = join "", ($inner =~ m[<t>(.+?)</t>]g);
        _decode_xml_entities($val) if $val;
      }
      elsif ($cell_type eq 's') {
        # this is a string cell; $val is a pointer into the global array of shared strings
        $val = $self->strings->[$val];
      }
      else {
        # this is a plain value
        ($val) = ($inner =~ m[<v>(.*?)</v>])           if !defined $val && $inner;
        _decode_xml_entities($val) if $val && $cell_type eq 'str';

        # if necessary, transform the numeric value into a formatted date
        if ($has_date_formatter && $style && looks_like_number($val) && $val >= 0) {
          my $date_style = $self->date_styles->[$style];
          $val = $self->formatted_date($val, $date_style)    if $date_style;
        }
      }

      # insert this value into the global data array
      $data[$row-1][$col-1] = $val;
    }
    else {die "unexpected regex match"}
  }

  # insert empty arrayrefs for empty rows
  $_ //= [] foreach @data;

  return \@data;
}


sub _table_targets {
  my ($self, $rel_xml) = @_;

  my @table_targets = $rel_xml =~ m[<Relationship .*? Target="../tables/table(\d+)\.xml"]g;
  return @table_targets; # a list of positive integers corresponding to table ids
}


sub _parse_table_xml {
  my ($self, $xml) = @_;

  state $table_regex = qr{
     <table .+? displayName="(\w+)"
            .+? ref="([:A-Z0-9]+)"
            .+? (headerRowCount="0")?
            .+?>
    }x;

  # extract relevant attributes from the <table> node
  my ($name, $ref, $no_headers) = $xml =~ /$table_regex/g
    or croak "invalid table XML";

  # column names. Other attributes from <tableColumn> nodes are ignored.
  my @columns = ($xml =~ m{<tableColumn [^>]+? name="([^"]+)"}gx);

  # decode entites for all string values
  _decode_xml_entities($_) for $name, @columns;

  return ($name, $ref, \@columns, $no_headers);
}


#======================================================================
# AUXILIARY FUNCTIONS
#======================================================================


sub _decode_xml_entities {
  state $xml_entities   = { amp  => '&',
                            lt   => '<',
                            gt   => '>',
                            quot => '"',
                            apos => "'",
                           };
  state $entity_names   = join '|', keys %$xml_entities;
  state $regex_entities = qr/&($entity_names);/;

  # substitute in-place
  $_[0] =~ s/$regex_entities/$xml_entities->{$1}/eg;
}


1;

__END__

=head1 NAME

Excel::ValueReader::XLSX::Backend::Regex - using regexes for extracting values from Excel workbooks

=head1 DESCRIPTION

This is one of two backend modules for L<Excel::ValueReader::XLSX>; the other
possible backend is L<Excel::ValueReader::XLSX::Backend::LibXML>.

This backend parses OOXML structures using regular expressions.

=head1 AUTHOR

Laurent Dami, E<lt>dami at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020-2023 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
