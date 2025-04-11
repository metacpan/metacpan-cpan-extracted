package Excel::ValueReader::XLSX::Backend::LibXML;
use utf8;
use 5.12.1;
use Moose;
use Scalar::Util             qw/looks_like_number/;
use XML::LibXML::Reader      qw/XML_READER_TYPE_END_ELEMENT/;
use Iterator::Simple         qw/iter/;

extends 'Excel::ValueReader::XLSX::Backend';

#======================================================================
# LAZY ATTRIBUTE CONSTRUCTORS
#======================================================================

sub _strings {
  my $self = shift;

  my $reader = $self->_xml_reader_for_zip_member('xl/sharedStrings.xml');

  my @strings;
  my $last_string;
 NODE:
  while ($reader->read) {
    next NODE if $reader->nodeType == XML_READER_TYPE_END_ELEMENT;
    my $node_name = $reader->name;

    if ($node_name eq 'si') {
      push @strings, $last_string if defined $last_string;
      $last_string = '';
    }
    elsif ($node_name eq '#text') {
      $last_string .= $reader->value;
    }
  }

  push @strings, $last_string if defined $last_string;

  return \@strings;
}


sub _workbook_data {
  my $self = shift;

  my %workbook_data = (sheets => {}, base_year => 1900);
  my $sheet_id  = 1;

  my $reader = $self->_xml_reader_for_zip_member('xl/workbook.xml');

 NODE:
  while ($reader->read) {
    next NODE if $reader->nodeType == XML_READER_TYPE_END_ELEMENT;

    if ($reader->name eq 'sheet') {
      my $name = $reader->getAttribute('name')
        or die "sheet node without name";
      $workbook_data{sheets}{$name} = $sheet_id++;
    }
    elsif ($reader->name eq 'workbookPr' and my $date_attr = $reader->getAttribute('date1904')) {
      $workbook_data{base_year} = 1904 if $date_attr eq '1' or $date_attr eq 'true'; # this workbook uses the 1904 calendar
    }
    elsif ($reader->name eq 'workbookView' and my $active_attr = $reader->getAttribute('activeTab')) {
      $workbook_data{active_sheet} = $active_attr + 1 if defined $active_attr;
    }
  }

  return \%workbook_data;
}


sub _date_styles {
  my $self = shift;

  state $date_style_regex = qr{[dy]|\bmm\b};
  my @date_styles;

  # read from the styles.xml zip member
  my $xml_reader = $self->_xml_reader_for_zip_member('xl/styles.xml');

  # start with Excel builtin number formats for dates and times
  my @numFmt = $self->Excel_builtin_date_formats;

  my $expected_subnode = undef;

  # add other date formats explicitly specified in this workbook
 NODE:
  while ($xml_reader->read) {
    next NODE if $xml_reader->nodeType == XML_READER_TYPE_END_ELEMENT;

    # special treatment for some specific subtrees -- see 'numFmt' and 'xf' below
    if ($expected_subnode) {
      my ($name, $depth, $handler) = @$expected_subnode;
      if ($xml_reader->name eq $name && $xml_reader->depth == $depth) {
        # process that subnode and go to the next node
        $handler->();
        next NODE;
      }
      elsif ($xml_reader->depth < $depth) {
        # finished handling subnodes; back to regular node treatment
        $expected_subnode = undef;
      }
    }

    # regular node treatement
    if ($xml_reader->name eq 'numFmts') {
      # start parsing nodes for numeric formats
      $expected_subnode = [numFmt => $xml_reader->depth+1 => sub {
                             my $id   = $xml_reader->getAttribute('numFmtId');
                             my $code = $xml_reader->getAttribute('formatCode');
                             $numFmt[$id] = $code if $id && $code && $code =~ $date_style_regex;
                           }];
    }

    elsif ($xml_reader->name eq 'cellXfs') {
      # start parsing nodes for cell formats
      $expected_subnode = [xf => $xml_reader->depth+1 => sub {
                             state $xf_count = 0;
                             my $numFmtId    = $xml_reader->getAttribute('numFmtId');
                             my $code        = $numFmt[$numFmtId]; # may be undef
                             $date_styles[$xf_count++] = $code;
                           }];
    }
  }

  return \@date_styles;
}



#======================================================================
# METHODS
#======================================================================

sub _xml_reader {
  my ($self, $xml) = @_;

  my $reader   = XML::LibXML::Reader->new(string     => $xml,
                                          no_blanks  => 1,
                                          no_network => 1,
                                          huge       => 1);
  return $reader;
}


sub _xml_reader_for_zip_member {
  my ($self, $member_name) = @_;

  my $contents = $self->_zip_member_contents($member_name);
  return $self->_xml_reader($contents);
}


sub _values {
  my ($self, $sheet, $want_iterator) = @_;

  # prepare for traversing the XML structure
  my $has_date_formatter = $self->frontend->date_formatter;
  my $sheet_member_name  = $self->_zip_member_name_for_sheet($sheet);
  my $xml_reader         = $self->_xml_reader_for_zip_member($sheet_member_name);


  # get sheet 'ref' attribute from the initial preamble
  my $ref;
 PREAMBLE:
  while ($xml_reader->read) {
    if ($xml_reader->name eq 'dimension') {
      $ref = $xml_reader->getAttribute('ref');
      last PREAMBLE;
    }
  }



  my ($row_num, $col_num, @rows) = (0, 0);
  my ($cell_type, $cell_style, $seen_node);

  # dual closure : may be used as an iterator or as a regular sub, depending on $want_iterator. Of course
  # it would have been simpler to just write an iterator, and call it in a loop if the client wants all rows
  # at once ... but thousands of additional sub calls would slow down the process. So this more complex implementation
  # is for the sake of processing speed.
  my $get_values = sub {

    # in iterator mode, if we have a row ready, just return it
    return shift @rows if $want_iterator and @rows > 1;

    # otherwise loop on matching nodes
  NODE:
    while ($xml_reader->read) {
      my $node_name = $xml_reader->name;
      my $node_type = $xml_reader->nodeType;

      $xml_reader->finish and last NODE   if $node_name eq 'sheetData' && $node_type == XML_READER_TYPE_END_ELEMENT;
      next NODE                           if $node_type == XML_READER_TYPE_END_ELEMENT;

      if ($node_name eq 'row') {
        my $prev_row = $row_num;
        $row_num     = $xml_reader->getAttribute('r') // $row_num+1;
        $col_num     = 0;
        push @rows, [] for 1 .. $row_num-$prev_row;

        # in iterator mode, if we have a closed empty row, just return it
        return shift @rows if $want_iterator and @rows > 1;
      }

      elsif ($node_name eq 'c') {
        my $A1_cell_ref = $xml_reader->getAttribute('r') // '';
        my ($col_A1, $given_row)  = ($A1_cell_ref =~ /^([A-Z]+)(\d+)$/);

        $given_row //= $row_num;
        if    ($given_row < $row_num) {die "cell claims to be in row $given_row while current row is $row_num"}
        elsif ($given_row > $row_num) {push @rows, [] for 1 .. $given_row-$row_num;
                                       $col_num = 0;
                                       $row_num = $given_row;}

        # deal with the col number given in the 'r' attribute, if present
        if ($col_A1) {$col_num = $Excel::ValueReader::XLSX::A1_to_num_memoized{$col_A1}
                             //= Excel::ValueReader::XLSX->A1_to_num($col_A1)}
        else         {$col_num++}

        $cell_type  = $xml_reader->getAttribute('t');
        $cell_style = $xml_reader->getAttribute('s');
        $seen_node  = '';
      }

      elsif ($node_name =~ /^[vtf]$/) {
        # remember that we have seen a 'value' or 'text' or 'formula' node
        $seen_node = $node_name;
      }

      elsif ($node_name eq '#text') {
        #start processing cell content

        my $val = $xml_reader->value;
        $cell_type //= '';

        if ($seen_node eq 'v')  {
          if ($cell_type eq 's') {
            if (looks_like_number($val)) {
              $val = $self->strings->[$val]; # string -- pointer into the global array of shared strings
            }
            else {
              warn "unexpected non-numerical value: $val inside a node of shape <v t='s'>\n";
            }
          }
          elsif ($cell_type eq 'e') {
            $val = undef; # error -- silently replace by undef
          }
          elsif ($cell_type =~ /^(n|d|b|str|)$/) {
            # number, date, boolean, formula string or no type : content is already in $val

          # if this is a date, replace the numeric value by the formatted date
            if ($has_date_formatter && $cell_style && looks_like_number($val) && $val >= 0) {
              my $date_style = $self->date_styles->[$cell_style];
              $val = $self->formatted_date($val, $date_style)    if $date_style;
            }
          }
          else {
            # handle unexpected cases
            warn "unsupported type '$cell_type' in cell L${row_num}C${col_num}\n";
            $val = undef;
          }

          # insert this value into the last row
          $rows[-1][$col_num-1] = $val;
        }

        elsif ($seen_node eq 't' && $cell_type eq 'inlineStr')  {
          # inline string -- accumulate all #text nodes until next cell
          no warnings 'uninitialized';
          $rows[-1][$col_num-1] .= $val;
        }

        elsif ($seen_node eq 'f')  {
          # formula -- just ignore it
        }

        else {
          # handle unexpected cases
          warn "unexpected text node in cell L${row_num}C${col_num}: $val\n";
        }
      }
    }

    # end of XML nodes. In iterator mode, return a row if we have one
    return @rows ? shift @rows : undef if $want_iterator;
  };

  # decide what to return depending on the dual mode
  my $retval = $want_iterator ? iter($get_values)         
                              : do {$get_values->(); \@rows}; # run the closure and return the rows

  return ($ref, $retval);
}




sub _table_targets {
  my ($self, $rel_xml) = @_;

  my $xml_reader = $self->_xml_reader($rel_xml);

  my @table_targets;

  # iterate through XML nodes
 NODE:
  while ($xml_reader->read) {
    my $node_name = $xml_reader->name;
    my $node_type = $xml_reader->nodeType;
    next NODE if $node_type == XML_READER_TYPE_END_ELEMENT;

    if ($node_name eq 'Relationship') {
      my $target     = $xml_reader->getAttribute('Target');
      if ($target =~ m[tables/table(\d+)\.xml]) {
        # just store the table id (positive integer)
        push @table_targets, $1;
      }
    }
  }

  return @table_targets;
}


sub _parse_table_xml {
  my ($self, $xml) = @_;

  my %table_info;

  my $xml_reader = $self->_xml_reader($xml);

  # iterate through XML nodes
 NODE:
  while ($xml_reader->read) {
    my $node_name = $xml_reader->name;
    my $node_type = $xml_reader->nodeType;
    next NODE if $node_type == XML_READER_TYPE_END_ELEMENT;

    if ($node_name eq 'table') {
      %table_info = (
        name       => $xml_reader->getAttribute('displayName'),
        ref        => $xml_reader->getAttribute('ref'),
        no_headers => do {my $has_headers = $xml_reader->getAttribute('headerRowCount');
                          defined $has_headers && !$has_headers},
        has_totals => $xml_reader->getAttribute('totalsRowCount'),
       );
    }
    elsif ($node_name eq 'tableColumn') {
      push @{$table_info{columns}}, $xml_reader->getAttribute('name');
    }
  }

  return \%table_info
}




1;


__END__


=head1 NAME

Excel::ValueReader::XLSX::Backend::LibXML - using LibXML for extracting values from Excel workbooks

=head1 DESCRIPTION

This is one of two backend modules for L<Excel::ValueReader::XLSX>; the other
possible backend is L<Excel::ValueReader::XLSX::Backend::Regex>.

This backend parses OOXML structures using L<XML::LibXML::Reader>.

=head1 AUTHOR

Laurent Dami, E<lt>dami at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020-2022 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
