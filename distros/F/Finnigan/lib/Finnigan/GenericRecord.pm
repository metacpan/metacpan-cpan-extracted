package Finnigan::GenericRecord;

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

  # To decode a combination of specific and generic content, simply
  # create a copy of this object and in it, combine
  # $header->field_templates with specific fields and call
  # Decoder->read. Just make sure the specific fields' keys start with
  # a number and have the form 'x|key', and that number is unique in
  # each field (does not co-incide with the range of numbers in the
  # header (which is 1 .. n).
  my $self = Finnigan::Decoder->read($stream, $field_templates);
  return bless $self, $class;
}

1;
__END__

=head1 NAME

Finnigan::GenericRecord -- a decoder for data structures defined by GenericDataHeader

=head1 SYNOPSIS

  use Finnigan;
  my $record = Finnigan::GenericRecord->decode(\*INPUT, $header);

=head1 DESCRIPTION

Finnigan::GenericRecord is a pass-through decorder that only passes
the field definitions it obtains from the header
(Finnigan::GenericDataHeader) to Finnigan::Decoder.

Because Thermo's GenericRecord objects are odered and may have
"virtual" gaps and section titles in them, the Finnigan::Decoder's
method of stashing the decoded data into a hash is not directly
applicable. A GenericRecord may have duplicate keys and the key order
needs to be preserved. That is why Finnigan::GenericRecord relies on
the B<field_templates> method of Finnigan::GenericDataHeader to insert
ordinal numbers into the keys.

=head2 METHODS

=over 4

=item decode

The constructor method

=back

=head1 SEE ALSO

Finnigan::GenericDataHeader

Finnigan::GenericDataDescriptor

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
