package Finnigan::FractionCollector;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';

use overload ('""' => 'stringify');
 

my @fields = (
              "low mz"  => ['d<', 'Float64'],
              "high mz" => ['d<', 'Float64'],
             );

sub decode {
  return bless Finnigan::Decoder->read($_[1], \@fields), $_[0];
}

sub low {
  shift->{data}->{"low mz"}->{value};
}

sub high {
  shift->{data}->{"high mz"}->{value};
}

sub stringify {
  my $self = shift;
  my $low = sprintf("%.2f", $self->{data}->{"low mz"}->{value});
  my $high = sprintf("%.2f", $self->{data}->{"high mz"}->{value});
  return "[$low-$high]";
}

1;
__END__

=head1 NAME

Finnigan::FractionCollector -- a decoder for FractionCollector, a mass range object in ScanEvent

=head1 SYNOPSIS

  use Finnigan;
  my $f = Finnigan::FractionCollector->decode(\*INPUT);
  say "$f";

=head1 DESCRIPTION

This object is just a container for a pair of double-precision floating point
numbers that define the M/z range of ions collected during a scan.

=head2 METHODS

=over 4

=item decode($stream)

The constructor method

=item low

Get the low M/z

=item high

Get the high M/z

=item stringify

Make a string representation of the object: C<[low-high]>, as in Thermo's "filter line"

=back

=head1 SEE ALSO

Finnigan::ScanEvent

Finnigan::ScanEventTemplate

L<uf-trailer>


=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
