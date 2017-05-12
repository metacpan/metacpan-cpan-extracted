package Finnigan::InstrumentLogRecord;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';

sub decode {
  my ($class, $stream, $field_templates) = @_;

  # This is a sleazy way of decoding this structure. The result will
  # be a hash whose keys start with the ordinal numbers of elements;
  # this answers the need to preserve order and to introduce gaps and
  # section titles commanded by the GenericDataHeader but not present
  # in the actual record. The field_templates() method of
  # GenericDataHeader modifies all keys by adding ordinals to them.
  my $self = Finnigan::Decoder->read($stream,
                                     [
                                      '0|time' => ['f<',  'Float32'],
                                      @$field_templates    # ordered templates from GenericDataHeader
                                     ]
                                    );
  return bless $self, $class;
}

sub time {
  shift->{data}->{'0|time'}->{value};
}

sub fields {
  my $self = shift;
  map{$self->{data}->{$_}}
    sort {(split /\|/, $a)[0] <=> (split /\|/, $b)[0]}
      grep {!/0\|time/}
        keys %{$self->{data}};
}

1;
__END__

=head1 NAME

Finnigan::InstrumentLogRecord -- a decoder for a single Instrument Log record

=head1 SYNOPSIS

  my $entry = Finnigan::InstrumentLogRecord->decode(\*INPUT, $header->ordered_field_templates);
  use Finnigan;
  my $i = 0;
  foreach my $field ($entry->fields) {
    say $entry->time
      . "\t" . $header->field($i)->label
        . "\t" . $field->{value};
    $j++;
  }

=head1 DESCRIPTION

This decoder is prototyped on Finnigan::GenericRecord, which is a
pass-through decorder that only passes the field definitions it
obtains from the header (Finnigan::GenericDataHeader) to
Finnigan::Decoder. It is essentially a copy of the
Finnigan::GenericRecord code with one specific field (retention time)
prepended to the template list.

Because Thermo's GenericRecord objects are odered and may have
"virtual" spacers and section titles in them, the Finnigan::Decoder's
method of stashing the decoded data into a hash is not directly
applicable. A GenericRecord may have duplicate keys and the key order
needs to be preserved. That is why Finnigan::GenericRecord relies on
the B<field_templates> method of Finnigan::GenericDataHeader to insert
ordinal numbers into the keys.

=head2 METHODS

=over 4

=item decode($stream)

The constructor method

=item time

Get the timestamp. The timestamp is retention time measured in seconds
and stored as floating-point value.

=item fields

Get the list of all fields in the record. Each field is decoded with
the Finnigan::GenericRecord decoder using the definitions from
Finnigan::GenericDataHeader, and it contains, for example, the
following data:

  {
    value => '8.1953125',
    type => 'Float32',
    addr => 803445,
    seq => 70,
    size => 4
  }

=back


=head1 SEE ALSO

Finnigan::GenericRecord

Finnigan::GenericDataHeader

Finnigan::GenericDataDescriptor

L<uf-log>

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
