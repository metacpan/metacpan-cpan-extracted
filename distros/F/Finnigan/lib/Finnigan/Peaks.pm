package Finnigan::Peaks;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';


sub decode {
  my $self = bless Finnigan::Decoder->read($_[1], ["count" => ['V', 'UInt32']]), $_[0];
  return $self->iterate_object(
                               $_[1],
                               $self->{data}->{count}->{value},
                               peaks => 'Finnigan::Peak'
                              );
}

sub count {
  shift->{data}->{count}->{value};
}

sub peaks {
  shift->{data}->{peaks}->{value};
}

sub peak {
  shift->{data}->{peaks}->{value};
}

sub all {
  my $d;
  return [
          map {$d = $_->{data}; [$d->{mz}->{value}, $d->{abundance}->{value}]}
          @{$_[0]->{data}->{peaks}->{value}}
         ];
}

sub list {
  my $self = shift;
  if ($self->peaks) {
    foreach my $peak ( @{$self->peaks} ) {
      print "$peak\n";
    }
  }
}

1;
__END__

=head1 NAME

Finnigan::Peaks -- a decoder for PeaksList, the list of peak centroids

=head1 SYNOPSIS

  use Finnigan;
  my $peaks = Finnigan::Peaks->decode(\*INPUT);
  say $peaks->addr;
  say $peaks->size;
  $peaks->list;

=head1 DESCRIPTION

This decoder reads the stream of floating-point numbers into a list of
L<Finnigan::Peak> objects, each containing an (M/z, abundance) pair.

It is a simple but full-featured decoder for the PeakList structure,
part of ScanDataPacket. The data it generates contain the seek
addresses, sizes and types of all decoded elements, no matter how
small. That makes it very handy in the exploration of the file format
and in writing new code, but it is not very efficient in production
work.

In performance-sensitive applications, the more lightweight
L<Finnigan::Scan> module should be used, which includes
L<Finnigan::Scan::CentroidList> and other related submodules. It can be
used as a drop-in replacement for the full-featured modules, but it
does not store the seek addresses and object types, greatly reducing
the overhead.

=head2 METHODS

=over 4

=item decode($stream)

The constructor method

=item count

Get the number of peaks in the list

=item peaks

Get the list of Finnigan::Peak objects

=item peak

Same as B<peaks>. I find the dereference expressions easier to read
when the reference name is singular: C<$scan-E<gt>peak-E<gt>[0]>
(rather than C<$scan-E<gt>peaks-E<gt>[0]>). However, I prefer the
plural form when there is no dereferencing: C<$peaks =
$scan-E<gt>peaks;>q

=item all

Get the reference to an array containing the pairs of abundance?
values of each centroided peak. This method avoids the expense of
calling the Finnigan::Peak accessors.

=item list

Print the entire peak list to STDOUT

=back


=head1 SEE ALSO

Finnigan::CentroidList

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
