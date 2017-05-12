package Finnigan::GenericDataHeader;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';

sub decode {
  my ($class, $stream) = @_;

  my $self = Finnigan::Decoder->read($stream, [n => ['V', 'UInt32']]);
  bless $self, $class;

  if ( $self->n ) {
    $self->iterate_object($stream, $self->n, field => 'Finnigan::GenericDataDescriptor');
  }

  # prepare the field templates
  my $ord = 1;
  foreach my $f ( @{$self->{data}->{"field"}->{value}} ) {
    push @{$self->{templates}}, $f->definition;
    push @{$self->{ordered_templates}}, $f->definition($ord++);
    push @{$self->{labels}}, $f->label;
  }

  return $self;
}

sub n {
  # the number of data descriptors
  shift->{data}->{"n"}->{value};
}

sub fields {
  shift->{data}->{"field"}->{value};
}

sub labels {
  shift->{labels};
}

sub field_templates {
  shift->{templates};
}

sub ordered_field_templates {
  shift->{ordered_templates};
}

1;
__END__

=head1 NAME

Finnigan::GenericDataHeader -- a decoder for GenericDataHeader -- a key to decoding generic data records

=head1 SYNOPSIS

  use Finnigan;
  my $h = Finnigan::GenericDataHeader->decode(\*INPUT);
  say $h->n;
  say $h->dump;

=head1 DESCRIPTION

GenericDataHeader drives the decoding of a generic record. It stores a
list of GenericDataDescriptor objects, each describing a field in the
record.

=head2 METHODS

=over 4

=item decode($stream)

The constructor method

=item n

Get the number of fields in each record

=item fields

Get the list of Finnigan::GenericDataDescriptor objects. Each
descriptor object corresponds to a field in the GenericRecord
structure to be decoded with this header.

=item labels

Get the list of descriptor labels in the order they occur in the header

=item field_templates

Get the list of unpack templates for the entire record in the form
that can be passed to Finnigan::Decoder.

=item ordered_field_templates

Get the list of unpack templates whose keys are tagged with ordinal
numbers to disambiguate possible duplicate keys and to preserve the
order of fields. This is necessary for decoding the
InstrumentLogRecord structures.



=back

=head1 SEE ALSO

Finnigan::GenericDataDescriptor

Finnigan::GenericRecord

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
