package Excel::ValueReader::XLSX::Backend::LibXML;
use utf8;
use 5.10.1;
use Moose;
use XML::LibXML::Reader qw/XML_READER_TYPE_END_ELEMENT/;

extends 'Excel::ValueReader::XLSX::Backend';

our $VERSION = '1.03';

#======================================================================
# LAZY ATTRIBUTE CONSTRUCTORS
#======================================================================

sub _strings {
  my $self = shift;

  my $reader = $self->_xml_reader_for_zip_member('xl/sharedStrings.xml');

  my @strings;
  my $last_string = '';
 NODE:
  while ($reader->read) {
    next NODE if $reader->nodeType == XML_READER_TYPE_END_ELEMENT;
    my $node_name = $reader->name;

    if ($node_name eq 'si') {
      push @strings, $last_string if $last_string;
      $last_string = '';
    }
    elsif ($node_name eq '#text') {
      $last_string .= $reader->value;
    }
  }

  push @strings, $last_string if $last_string;

  return \@strings;
}


sub _workbook_data {
  my $self = shift;

  my %sheets;
  my $sheet_id  = 1;
  my $base_year = 1900;

  my $reader = $self->_xml_reader_for_zip_member('xl/workbook.xml');

 NODE:
  while ($reader->read) {
    next NODE if $reader->nodeType == XML_READER_TYPE_END_ELEMENT;

    if ($reader->name eq 'sheet') {
      my $name = $reader->getAttribute('name')
        or die "sheet node without name";
      $sheets{$name} = $sheet_id++;
    }
    elsif ($reader->name eq 'workbookPr' && $reader->getAttribute('date1904')) {
      $base_year = 1904; # this workbook uses the 1904 calendar
    }
  }

  return {sheets => \%sheets, base_year => $base_year};
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

sub _xml_reader_for_zip_member {
  my ($self, $member_name) = @_;

  my $contents = $self->_zip_member_contents($member_name);
  my $reader   = XML::LibXML::Reader->new(string     => $contents,
                                          no_blanks  => 1,
                                          no_network => 1,
                                          huge       => 1);
  return $reader;
}

sub values {
  my ($self, $sheet) = @_;

  # prepare for traversing the XML structure
  my $has_date_formatter = $self->frontend->date_formatter;
  my $sheet_member_name  = $self->_zip_member_name_for_sheet($sheet);
  my $xml_reader         = $self->_xml_reader_for_zip_member($sheet_member_name);
  my @data;
  my ($row, $col, $cell_type, $cell_style, $seen_node);

  # iterate through XML nodes
 NODE:
  while ($xml_reader->read) {
    next NODE if $xml_reader->nodeType == XML_READER_TYPE_END_ELEMENT;
    my $node_name = $xml_reader->name;

    if ($node_name eq 'c') {
      # new cell node : store its col/row reference and its type
      my $A1_cell_ref = $xml_reader->getAttribute('r');
      ($col, $row)    = ($A1_cell_ref =~ /^([A-Z]+)(\d+)$/);
      $col            = $self->A1_to_num($col);
      $cell_type      = $xml_reader->getAttribute('t');
      $cell_style     = $xml_reader->getAttribute('s');
      $seen_node      = '';
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
          $val = $self->strings->[$val]; # string -- pointer into the global
                                         # array of shared strings
        }
        elsif ($cell_type eq 'e') {
          $val = undef; # error -- silently replace by undef
        }
        elsif ($cell_type =~ /^(n|d|b|str|)$/) {
          # number, date, boolean, formula string or no type : content is already in $val

          # if this is a date, replace the numeric value by the formatted date
          if ($has_date_formatter && $cell_style && defined $val && $val >= 0) {
            my $date_style = $self->date_styles->[$cell_style];
            $val = $self->formatted_date($val, $date_style)    if $date_style;
          }
        }
        else {
          # handle unexpected cases
          warn "unsupported type '$cell_type' in cell L${row}C${col}\n";
          $val = undef;
        }

        # insert this value into the global data array
        $data[$row-1][$col-1] = $val;
      }

      elsif ($seen_node eq 't' && $cell_type eq 'inlineStr')  {
        # inline string -- accumulate all #text nodes until next cell
        no warnings 'uninitialized';
        $data[$row-1][$col-1] .= $val;
      }

      elsif ($seen_node eq 'f')  {
        # formula -- just ignore it
      }

      else {
        # handle unexpected cases
        warn "unexpected text node in cell L${row}C${col}: $val\n";
      }
    }
  }

  # insert arrayrefs for empty rows
  $_ //= [] foreach @data;

  return \@data;
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

Copyright 2020,2021 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
