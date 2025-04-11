package Excel::ValueReader::XLSX::Backend::Regex;
use utf8;
use 5.12.1;
use Moose;
use Scalar::Util             qw/looks_like_number/;
use Iterator::Simple         qw/iter/;

extends 'Excel::ValueReader::XLSX::Backend';


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

  my %workbook_data;

  # read from the workbook.xml zip member
  my $workbook = $self->_zip_member_contents('xl/workbook.xml');

  # extract sheet names
  my @sheet_names        = ($workbook =~ m[<sheet name="(.+?)"]g);
  $workbook_data{sheets} = {map {$sheet_names[$_] => $_+1} 0 .. $#sheet_names};

  # does this workbook use the 1904 calendar ?
  my ($date1904) = $workbook =~ m[date1904="(.+?)"];
  $workbook_data{base_year} = $date1904 && $date1904 =~ /^(1|true)$/ ? 1904 : 1900;

  # active sheet
  my ($active_tab) = $workbook =~ m[<workbookView[^>]+activeTab="(\d+)"];
  $workbook_data{active_sheet} = $active_tab + 1 if defined $active_tab;

  return \%workbook_data;
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
    push @xf_nodes, _xml_attrs($1);
  }
  return @xf_nodes;
}


#======================================================================
# METHODS
#======================================================================

sub _values {
  my ($self, $sheet, $want_iterator) = @_;

  # regex for the initial preamble
  state $preamble_regex = qr(
     <dimension\s+ref="([A-Z]+\d+(?::[A-Z]+\d+)?)"/>    # node specifying the range of defined cells
     .*?
     <sheetData>                                        # start container node for actual rows and cells content
     )xs;

  # regex for extracting information from cell nodes
  state $row_or_cell_regex = qr(
     <(row)                  # row tag ($1)
       (?:\s+r="(\d+)")?     # optional row number ($2)
       [^>/]*?               # unused attrs
     >                       # end of tag

     |                       # .. or ..

     <(c)                    # cell tag ($3)
      (?: \s+ | (?=>) )      # either a space before attrs, or end of tag
      (?:r="([A-Z]+)(\d+)")? # capture col ($4) and row ($5)
      [^>/]*?                # unused attrs
      (?:s="(\d+)"\s*)?      # style attribute ($6)
      (?:t="(\w+)"\s*)?      # type attribute ($7)
     (?:                     # non-capturing group for an alternation :
        />                   # .. either an xml closing without content
      |                      # or
        >                    # .. closing xml tag, followed by ..
      (?:
         <v>(.+?)</v>        #    .. a value ($8)
        |                    #    or 
          (.+?)              #    .. some node content ($9)
       )
       </c>                  #    followed by a closing cell tag
      )
    )xs;
  # NOTE : this regex uses positional capturing groups; it would be more readable with named
  # captures instead, but this would double the execution time on big Excel files, so I
  # stick to plain old capturing groups.

  # does this instance want date formatting ?
  my $has_date_formatter = $self->frontend->date_formatter;

  # get worksheet XML
  my $contents = $self->_zip_member_contents($self->_zip_member_name_for_sheet($sheet));

  # parse the preamble
  my ($ref) = $contents =~ /$preamble_regex/g; # /g to leave the pos() cursor before the 1st cell

  # variables for the closure below
  my ($row_num, $col_num, @rows) = (0, 0);

  # dual closure : may be used as an iterator or as a regular sub, depending on $want_iterator. Of course
  # it would have been simpler to just write an iterator, and call it in a loop if the client wants all rows
  # at once ... but thousands of additional sub calls would slow down the process. So this more complex implementation
  # is for the sake of processing speed.
  my $get_values = sub {

    # in iterator mode, if we have a row ready, just return it
    return shift @rows if $want_iterator and @rows > 1;

    # otherwise loop on matching nodes
    while ($contents =~ /$row_or_cell_regex/cg) { # /g allows the iterator to remember where the last cell left off
      if ($1) {                # this is a 'row' tag
        my $prev_row = $row_num;
        $row_num     = $2 // $row_num+1; # if present, capture group $2 is the row number
        $col_num     = 0;
        push @rows, [] for 1 .. $row_num-$prev_row;

        # in iterator mode, if we have a closed empty row, just return it
        return shift @rows if $want_iterator and @rows > 1;
      }
      elsif ($3) {             # this is a 'c' tag
        my ($col_A1, $given_row, $style, $cell_type, $val, $inner) = ($4, $5, $6, $7, $8, $9);

        # deal with the row number given in the 'r' attribute, if present
        $given_row //= $row_num;
        if    ($given_row < $row_num) {die "cell claims to be in row $given_row while current row is $row_num"}
        elsif ($given_row > $row_num) {push @rows, [] for 1 .. $given_row-$row_num;
                                       $col_num = 0;
                                       $row_num = $given_row;}


        # deal with the col number given in the 'r' attribute, if present
        if ($col_A1) {$col_num = $Excel::ValueReader::XLSX::A1_to_num_memoized{$col_A1}
                             //= Excel::ValueReader::XLSX->A1_to_num($col_A1)}
        else         {$col_num++}

        # handle the cell value according to cell type
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

        # insert this value into the last row
        $rows[-1][$col_num-1] = $val;
      }
      else {die "found a node which is neither a <row> nor a <c> (cell)"}
    }

    # end of regex matches. In iterator mode, return a row if we have one
    return @rows ? shift @rows : undef if $want_iterator;
  };

  # decide what to return depending on the dual mode
  my $retval = $want_iterator ? iter($get_values)         
                              : do {$get_values->(); \@rows}; # run the closure and return the rows

  return ($ref, $retval);
}


sub _table_targets {
  my ($self, $rel_xml) = @_;

  my @table_targets = $rel_xml =~ m[<Relationship .*? Target="../tables/table(\d+)\.xml"]g;
  return @table_targets; # a list of positive integers corresponding to table ids
}


sub _parse_table_xml {
  my ($self, $xml) = @_;

  $xml =~ m[<table (.*?)>]g and my $table_attrs = _xml_attrs($1)
    or die "invalid table XML: $xml";

  # extract relevant attributes
  my %table_info = (
    name       => $table_attrs->{displayName},
    ref        => $table_attrs->{ref},
    no_headers => exists $table_attrs->{headerRowCount} && !$table_attrs->{headerRowCount},
    has_totals => $table_attrs->{totalsRowCount},
    columns    => [$xml =~ m{<tableColumn [^>]+? name="([^"]+)"}gx],
   );


  # decode entites for all string values
  _decode_xml_entities($_) for $table_info{name}, @{$table_info{columns}};

  return \%table_info;
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


sub _xml_attrs {
  my $attrs_list = shift;
  my %attr       = $attrs_list =~ m[(\w+)="(.+?)"]g;
  return \%attr;
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

=cut
