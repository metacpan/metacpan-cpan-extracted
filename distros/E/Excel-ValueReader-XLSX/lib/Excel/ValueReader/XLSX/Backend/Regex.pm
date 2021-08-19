package Excel::ValueReader::XLSX::Backend::Regex;
use utf8;
use 5.10.1;
use Moose;
extends 'Excel::ValueReader::XLSX::Backend';

our $VERSION = '1.02';

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
  my $base_year  = $date1904 ? 1904 : 1900;

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
  my ($row, $col, $cell_type, $seen_node);

  # regex for extracting information from cell nodes
  state $cell_regex = qr(
     <c\                     # initial cell tag
      r="([A-Z]+)(\d+)"      # capture col and row ($1 and $2)
      [^>/]*?                # unused attrs
      (?:s="(\d+)"\s*)?      # style attribute ($3)
      (?:t="(\w+)"\s*)?      # type attribute ($4)
     (?:                     # non-capturing group for an alternation :
        />                   # .. either an xml closing without content
      |                      # or
        >                    # .. closing xml tag, followed by
      (?:

         <v>(.+?)</v>        #    .. a value ($5)
        |                    #    or 
          (.+?)              #    .. some node content ($6)
       )
       </c>                  #    followed by a closing cell tag
      )
    )x;
  # NOTE : this regex uses capturing groups; it would be more readable with named
  # captures instead, but this doubles the execution time on big Excel files, so I
  # came back to plain old capturing groups.

  # does this instance want date formatting ?
  my $has_date_formatter = $self->frontend->date_formatter;

  # parse worksheet XML, gathering all cells
  my $contents = $self->_zip_member_contents($self->_zip_member_name_for_sheet($sheet));
  while ($contents =~ /$cell_regex/g) {
    my ($col, $row, $style, $cell_type, $val, $inner) = ($self->A1_to_num($1), $2, $3, $4, $5, $6);

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
      if ($has_date_formatter && $style && defined $val && $val >= 0) {
        my $date_style = $self->date_styles->[$style];
        $val = $self->formatted_date($val, $date_style)    if $date_style;
      }
    }

    # insert this value into the global data array
    $data[$row-1][$col-1] = $val;
  }

  # insert arrayrefs for empty rows
  $_ //= [] foreach @data;

  return \@data;
}

#======================================================================
# AUXILIARY FUNCTIONS
#======================================================================


sub _decode_xml_entities {
  state %xml_entities   = ( amp  => '&',
                            lt   => '<',
                            gt   => '>',
                            quot => '"',
                            apos => "'",
                           );
  state $entity_names   = join '|', keys %xml_entities;
  state $regex_entities = qr/&($entity_names);/;

  # substitute in-place
  $_[0] =~ s/$regex_entities/$xml_entities{$1}/eg;
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

Copyright 2020,2021 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
