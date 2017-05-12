package Finnigan::Reaction;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';

use overload ('""' => 'stringify');

my $fields = [
              "precursor mz"      => ['d<', 'Float64'],
              "unknown double"    => ['d<', 'Float64'],
              "energy"            => ['d<', 'Float64'],
              "unknown long[1]"   => ['V',  'UInt32'],
              "unknown long[2]"   => ['V',  'UInt32'],
             ];

sub decode {
  my ($class, $stream) = @_;

  my $self = Finnigan::Decoder->read($stream, $fields);

  return bless $self, $class;
}

sub precursor {
  shift->{data}->{"precursor mz"}->{value};
}

sub energy {
  shift->{data}->{"energy"}->{value};
}

sub stringify {
  my $self = shift;
  my $precursor = sprintf("%.2f", $self->precursor);
  my $energy = sprintf("%.2f", $self->energy);
  return "$precursor\@$Finnigan::activationMethod$energy";
}

1;
__END__

=head1 NAME

Finnigan::Reaction -- a decoder for Reaction, the container for precursor mass and fragmentation energy

=head1 SYNOPSIS

  use Finnigan;
  my $r = Finnigan::Reaction->decode(\*INPUT);
  say $r->precursor;
  say $r->enengy;

=head1 DESCRIPTION

This object contains a couple of double-precision floating point
numbers that define the precursor ion M/z and the energy
of the fragmentation reaction.

There are other elements that currently remain unknown: a double (set
to 1.0 in all observations) and a couple longs.


=head2 METHODS

=over 4

=item decode($stream)

The constructor method

=item precursor

Get the precursor M/z

=item energy

Get the fragmentation energy

=item stringify

Make a short text representation of the object (found inside Therom's "filter line")

=back

=head1 SEE ALSO

Finnigan::ScanEvent

L<uf-trailer>


=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
