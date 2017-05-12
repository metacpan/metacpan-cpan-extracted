package Finnigan::ProfileChunk;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';


my $preamble_0 = [
                  "first bin"     => ['V', 'UInt32'],
                  "nbins"         => ['V', 'UInt32'],
                 ];

my $preamble = [@$preamble_0, "fudge" => ['f<', 'Float32']];

sub decode {
  my $self;
  if ( $_[2] > 0 ) { # the layout flag in the packet header
    $self = Finnigan::Decoder->read($_[1], $preamble);
  }
  else {
    $self = Finnigan::Decoder->read($_[1], $preamble_0);
  }
  bless $self, $_[0]; # class
  return $self->iterate_scalar($_[1], $self->{data}->{"nbins"}->{value}, signal => ['f<', 'Float32']);
}

sub nbins {
  shift->{data}->{"nbins"}->{value};
}

sub first_bin {
  shift->{data}->{"first bin"}->{value};
}

sub fudge {
  shift->{data}->{fudge}->{value};
}

sub signal {
  shift->{data}->{"signal"}->{value};
}

1;
__END__

=head1 NAME

Finnigan::ProfileChunk -- a full-featured decoder for a single ProfileChunk structure

=head1 SYNOPSIS

  use Finnigan;

  my $chunk = Finnigan::ProfileChunk->decode( \*INPUT, $packet_header->layout );
  say $chunk->first_bin;
  say $chunk->fudge;
  my $nbins = $chunk->nbins;
  say $chunk->fudge;
  foreach my $i ( 0 .. $nbins - 1) {
    say $chunk->signal->[$i];
  }

=head1 DESCRIPTION

Finningan::ProfileChunk is a full-featured decoder for the ProfileChunk structure, a segment of a Profile. The data it generates contain the seek addresses, sizes and types of all decoded elements, no matter how small. That makes it very handy in the exploration of the file format and in writing new code, but it is not very efficient in production work.

In performance-sensitive applications, the more lightweight Finnigan::Scan? module should be used, which includes Finnigan::Scan::ProfileChunk? and other related submodules. It can be used as a drop-in replacement for the full-featured modules, but it does not store the seek addresses and object types, greatly reducing the overhead.

Every scan done in the B<profile mode> has a profile, which is either a time-domain signal or a frequency spectrum accumulated in histogram-like bins.

A profile can be either raw or filtered. Filtered profiles are sparse; they consist of separate data chunks. Each chunk consists of a contiguous range of bins containing the above-threshold signal. The bins whose values fall below a cerain threshold are simply discarded, leaving gaps in the profile -- the reason for the ProfileChunk structure to exist.

One special case is raw profile, which preserves all data. Since there are no gaps in a raw profile, it is represented by a single chunk covering the entire range of bins, so the same container structure is suitable for complete profiles, as well as for sparse ones.

The bins store the signal intensity, and the bin co-ordinates are typically the frequencies of Fourier-transformed signal. Since the bins are equally spaced in the frequency domain, only the first bin frequency is stored in each profile header. The bin width is common for all bins and it is also stored in the same header. With these data, it is possible to calculate the bin values based on the bin indices.

Each ProfileChunk structure stores the first bin index, the number of bins, and a list of bin intensities. Additionally, in some layouts, it stores a small floating-point value that most probably represents the instrument drift relative to its calibrated value; this "fudge" value is added to the result of the the frequency to M/z conversion. The chunk layout (the presence or absence of the fudge value) is determined by the layout flag in PacketHeader.

=head2 Methods

=over 4

=item decode

The constructor method

=item nbins

Get the number of bins chunks in the chunk

=item first_bin

Get the index of the first bin in the chunk

=item fudge

Get the the value of conversion bias

=item signal

Get the list of bin values

=back

=head1 EXPORT

None

=head1 SEE ALSO

Finnigan::Profile

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
