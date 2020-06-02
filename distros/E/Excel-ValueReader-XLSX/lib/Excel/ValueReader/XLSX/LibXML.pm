package Excel::ValueReader::XLSX::LibXML;
use utf8;
use Moose;
use XML::LibXML::Reader;

our $VERSION = '1.0';

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

  my $reader = $self->_reader_for_member('xl/sharedStrings.xml');

  my @strings;
  my $last_string = '';
  while ($reader->read) {
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


sub _sheets {
  my $self = shift;

  my $reader = $self->_reader_for_member('xl/workbook.xml');
  my %sheets;

  my $id = 1;
  while ($reader->read) {
    next unless $reader->name eq 'sheet';
    my $name = $reader->getAttribute('name')
      or die "sheet node without name";
    $sheets{$name} = $id++;
  }

  return \%sheets;
}

#======================================================================
# METHODS
#======================================================================

sub _reader_for_member {
  my ($self, $member) = @_;

  my $reader = XML::LibXML::Reader->new(string     => $self->_member_contents($member),
                                        no_blanks  => 1,
                                        no_network => 1,
                                        huge       => 1);
  return $reader;
}

sub values {
  my ($self, $sheet) = @_;

  # prepare for traversing the XML structure
  my $reader = $self->_reader_for_member($self->sheet_member($sheet));
  my @data;
  my ($row, $col, $cell_type, $seen_node);

  # iterate through XML nodes
  while ($reader->read) {
    my $node_name = $reader->name;

    if ($node_name eq 'c') {
      # new cell node : store its col/row reference and its type
      my $A1_cell_ref = $reader->getAttribute('r');
      ($col, $row)    = ($A1_cell_ref =~ /^([A-Z]+)(\d+)$/);
      $col            = $self->A1_to_num($col);
      $cell_type      = $reader->getAttribute('t');
      $seen_node      = '';
    }

    elsif ($node_name =~ /^[vtf]$/) {
      # remember we have seen a 'value' or 'text' or 'formula' node
      $seen_node = $node_name;
    }

    elsif ($node_name eq '#text') {
      #start processing cell content

      my $val = $reader->value;
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
          # number, date, boolean, formula string or no type :
          # nothing to do, content is already in $val
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

Excel::ValueReader::XLSX::LibXML - using LibXML for extracting values from Excel workbooks

=head1 DESCRIPTION

This is one of two backend modules for L<Excel::ValueReader::XLSX>; the other
possible backend is L<Excel::ValueReader::XLSX::Regex>.

This backend parses OOXML structures using L<XML::LibXML::Reader>.

=head1 AUTHOR

Laurent Dami, E<lt>dami at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
