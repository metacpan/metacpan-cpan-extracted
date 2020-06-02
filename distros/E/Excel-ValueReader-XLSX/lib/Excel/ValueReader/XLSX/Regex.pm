package Excel::ValueReader::XLSX::Regex;
use utf8;
use Moose;
use 5.10.1;

#======================================================================
# GLOBAL VARIABLES
#======================================================================

our $VERSION = '1.0';

my %xml_entities   = ( amp  => '&',
                       lt   => '<',
                       gt   => '>',
                       quot => '"',
                       apos => "'",  );
my $entity_names   = join '|', keys %xml_entities;
my $regex_entities = qr/&($entity_names);/;

#======================================================================
# ATTRIBUTES
#======================================================================

has 'frontend'  => (is => 'ro',   isa => 'Excel::ValueReader::XLSX', 
                    required => 1, weak_ref => 1,
                    handles => [qw/sheet_member _member_contents strings A1_to_num/]);

#======================================================================
# LAZY ATTRIBUTE CONSTRUCTORS
#======================================================================

sub _strings {
  my $self = shift;
  my @strings;

  # read from the sharedStrings zip member
  my $contents = $self->_member_contents('xl/sharedStrings.xml');

  # iterate on <si> nodes
  while ($contents =~ m[<si>(.*?)</si>]g) {
    my $innerXML = $1;

    # concatenate contents from all <t> nodes (usually there is only 1)
    my $string   = join "", ($innerXML =~ m[<t[^>]*>(.+?)</t>]g);

    # decode entities
    $string =~ s/$regex_entities/$xml_entities{$1}/eg;

    push @strings, $string;
  }

  return \@strings;
}


sub _sheets {
  my $self = shift;

  # read from the workbook.xml zip member
  my $contents = $self->_member_contents('xl/workbook.xml');

  my @sheet_names = ($contents =~ m[<sheet name="(.+?)"]g);
  my %sheets      = map {$sheet_names[$_] => $_+1} 0 .. $#sheet_names;

  return \%sheets;
}


#======================================================================
# METHODS
#======================================================================

sub values {
  my ($self, $sheet) = @_;
  my @data;
  my ($row, $col, $cell_type, $seen_node);

  state $cell_regex = qr(
     <c\                     # initial cell tag
      r="([A-Z]+)(\d+)"      # capture col and row ($1 and $2)
      [^>/]*?                # unused attrs
      (?:t="(\w+)"\s*)?      # type attribute ($3)
     (?:                     # non-capturing group for an alternation :
        />                   # .. either an xml closing without content
      |                      # or
        >                    # .. closing xml tag, followed by
      (?:
         <v>(.+?)</v>        #    .. a value ($4)
        |                    #    or 
          (.+?)              #    .. some node content ($5)
       )
       </c>                  #    followed by a closing cell tag
      )
    )x;
  # NOTE : this regex uses capturing groups; I tried with named captures
  # but this doubled the execution time on big Excel files

  # parse worksheet XML, gathering all cells
  my $contents = $self->_member_contents($self->sheet_member($sheet));
  while ($contents =~ /$cell_regex/g) {
    my ($col, $row, $cell_type, $val, $inner) = ($self->A1_to_num($1), $2, $3, $4, $5);

    # handle cell value according to cell type
    $cell_type //= '';
    if ($cell_type eq 'inlineStr') {
      # this is an inline string; gather all <t> nodes within the cell node
      $val = join "", ($inner =~ m[<t>(.+?)</t>]g);
      $val =~ s/$regex_entities/$xml_entities{$1}/eg if $val;
    }
    elsif ($cell_type eq 's') {
      # this is a string cell; $val is a pointer into the global array of shared strings
      $val = $self->strings->[$val];
    }
    else {
      ($val) = ($inner =~ m[<v>(.*?)</v>])           if !defined $val && $inner;
      $val =~ s/$regex_entities/$xml_entities{$1}/eg if $val && $cell_type eq 'str';
    }

    # insert this value into the global data array
    $data[$row-1][$col-1] = $val;
  }

  # insert arrayrefs for empty rows
  $_ //= [] foreach @data;

  return \@data;
}


1;

__END__

=head1 NAME

Excel::ValueReader::XLSX::Regex - using regexes for extracting values from Excel workbooks

=head1 DESCRIPTION

This is one of two backend modules for L<Excel::ValueReader::XLSX>; the other
possible backend is L<Excel::ValueReader::XLSX::LibXML>.

This backend parses OOXML structures using regular expressions.

=head1 AUTHOR

Laurent Dami, E<lt>dami at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
