package Finnigan::Peak;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';

use overload ('""' => 'stringify');

my $fields = [
              "mz"        => ['f<', 'Float32'],
              "abundance" => ['f<', 'Float32'],
             ];

sub decode {
  return bless Finnigan::Decoder->read($_[1], $fields), $_[0];
}

sub mz {
  $_[0]->{data}->{"mz"}->{value};
}

sub abundance {
  $_[0]->{data}->{"abundance"}->{value};
}

sub stringify {
  my $self = shift;
  my $mz = $self->{data}->{mz}->{value};
  my $abundance = $self->{data}->{abundance}->{value};
  return "$mz\t$abundance";
}

1;
__END__

=head1 NAME

Finnigan::Peak -- a full-featured decoder for a single (M/z, abundance) pair, an element of the PeakList structure

=head1 SYNOPSIS

  use Finnigan;
  my $peak = Finnigan::Peak->decode(\*INPUT);
  say $peak->mz;
  say $peak->abundance;
  say "$peak";

=head1 DESCRIPTION

This decoder is useless in normal life. It is a full-featured decoder
for the pair of floating-point numbers representing the centroid
_M/z_ and intensity of a peak. The data it generates contain the seek
addresses, sizes and types of both attributes. These features may be
useful in the exploration of the file format and in writing new code,
but not in production work.

In performance-sensitive applications, the more lightweight
Finnigan::Scan module should be used, which includes
Finnigan::Scan::CentroidList and other related submodules. It does not
store the seek addresses and object types, greatly reducing the
overhead.

There is no equivalent object in Finnigan::Scan::CentroidList; it
simply uses a pair of scalars for the data, since the location data
and decoding templates are jettisoned, eliminating the need for
an object.


=head2 METHODS

=over 4

=item decode($stream)

The constructor method

=item mz

Get the M/z value, the first in the pair

=item abundance

Get the abundance value, the second in the pair

=item stringify

Get both attributes concatenated with a tab character. Used in the
list method of the containing object, Finnigan::Peaks

=back

=head1 SEE ALSO

Finnigan::Peaks

L<uf-scan>

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
