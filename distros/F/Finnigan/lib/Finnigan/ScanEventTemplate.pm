package Finnigan::ScanEventTemplate;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';

use overload ('""' => 'stringify');

sub decode {
  my ($class, $stream, $version) = @_;

  my @fields = (
                "preamble"                      => ['object',  'Finnigan::ScanEventPreamble'],
                "presumed controller type"      => ['V',       'UInt32'],
                "presumed controller number"    => ['V',       'UInt32'],
                "fraction collector"            => ['object', 'Finnigan::FractionCollector'],
                "unknown long[3]"               => ['V',       'UInt32'],
                "unknown long[4]"               => ['V',       'UInt32'],
                "unknown long[5]"               => ['V',       'UInt32'],
               );

  my $self = Finnigan::Decoder->read($stream, \@fields, $version);
  bless $self, $class;
  return $self;
}

sub preamble {
  shift->{data}->{"preamble"}->{value};
}

sub controllerType {
  shift->{data}->{"presumed controller type"}->{value};
}

sub controllerNumber {
  shift->{data}->{"presumed controller number"}->{value};
}

sub fraction_collector {
  shift->{data}->{"fraction collector"}->{value};
}


sub stringify {
  my $self = shift;

  my $p = $self->preamble;
  my $f = $self->fraction_collector;
  return "$p $f";
}


1;
__END__

=head1 NAME

Finnigan::ScanEventTemplate -- a decoder for ScanEventTemplate, the prototype scan descriptor

=head1 SYNOPSIS

  use Finnigan;
  my $e = Finnigan::ScanEventTemplate->decode(\*INPUT);
  say $e->size;
  say $e->dump;
  say join(" ", $e->preamble->list(decode => 'yes'));
  say $e->preamble->analyzer(decode => 'yes');
  $e->fraction_collector->dump;
  $e->reaction->dump if $e->type == 1 # Reaction will not be present in MS1

=head1 DESCRIPTION

This is a template structure that apparently forms the core of each
ScanEvent structure corresponding to an individual scan. It is an
elment of MSScanEvent hirerachy (that's the name used by Thermo),
which models the grouping of scan events into segments.

=head2 METHODS

=over 4

=item decode

The constructor method

=item preamble

Get the Finnigan::ScanEventPreamble object

=item controllerType

Get the virtual controller type for this event (a guess; data not verified)

=item controllerNumber

Get the virtual controller number for this event (a guess; data not verified)

=item fraction_collector

Get the Finnigan::FractionCollector object

=item stringify

Make a short text representation of the object

=back

=head1 SEE ALSO

Finnigan::ScanEvent

Finnigan::ScanEventPreamble

Finnigan::FractionCollector

Finnigan::Reaction

L<uf-segments>

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
