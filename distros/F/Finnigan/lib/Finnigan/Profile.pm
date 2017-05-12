package Finnigan::Profile;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Carp;
use Finnigan;
use base 'Finnigan::Decoder';

my $preamble = [
                "first value" => ['d<', 'Float64'],
                "step"        => ['d<', 'Float64'],
                "peak count"  => ['V',  'UInt32'],
                "nbins"       => ['V',  'UInt32'],
               ];


sub decode {
  my $self = bless Finnigan::Decoder->read($_[1], $preamble), $_[0];
  return $self->iterate_object($_[1], $self->{data}->{"peak count"}->{value}, chunks => 'Finnigan::ProfileChunk', $_[2]); # the last arg is layout
}

sub nchunks { # in place of the erroneous "peak_count"
  shift->{data}->{"peak count"}->{value};
}

sub peak_count { # deprecated
  shift->{data}->{"peak count"}->{value};
}

sub nbins {
  shift->{data}->{"nbins"}->{value};
}

sub first_value {
  shift->{data}->{"first value"}->{value};
}

sub step {
  my $self = shift;
  confess "undefined" unless $self;
  $self->{data}->{"step"}->{value};
}

sub chunks {
  shift->{data}->{"chunks"}->{value};
}

sub chunk { # a syntactic eye-sore remover
  shift->{data}->{"chunks"}->{value};
}

sub set_converter {
  $_[0]->{converter} = $_[1];
}

sub set_inverse_converter {
  $_[0]->{"inverse converter"} = $_[1];
}

sub bins {
  my ($self, $range, $add_zeroes) = @_;
  my @list;
  my $start = $self->{data}->{"first value"}->{value};
  my $step = $self->{data}->{step}->{value};
  unless ( $range ) {
    unless ( exists $self->{converter} ) {
      $range = [$start, $start + $self->{data}->{nbins}->{value} * $step];
    }
  }

  push @list, [$range->[0], 0] if $add_zeroes;
  my $last_bin_written = 0;

  my $shift = 0; # this is declared outside the chunk loop to allow
                 # writing the empty bin following the last chunk with
                 # the same amount of shift as in the last chunk

  foreach my $i ( 0 .. $self->{data}->{"peak count"}->{value} - 1 ) { # each chunk
    my $chunk = $self->{data}->{chunks}->{value}->[$i];
    my $first_bin = $chunk->{data}->{"first bin"}->{value};
    $shift = $chunk->{data}->{fudge} ? $chunk->{data}->{fudge}->{value} : 0;
    my $x = $start + $first_bin * $step;

    if ( $add_zeroes and $last_bin_written < $first_bin - 1) {
      # add an empty bin ahead of the chunk, unless there is no gap
      # between this and the previous chunk
      my $x0 = $x - $step;
      my $x_conv = exists $self->{converter} ? &{$self->{converter}}($x0) + $shift : $x0;
      push @list, [$x_conv, 0];
    }

    foreach my $j ( 0 .. $chunk->{data}->{nbins}->{value} - 1) {
      my $x_conv = exists $self->{converter} ? &{$self->{converter}}($x) + $shift : $x;
      $x += $step;
      if ( $range ) {
        if ( exists $self->{converter} ) {
          next unless $x_conv >= $range->[0] and $x_conv <= $range->[1];
        }
        else {
          # frequencies have the reverse order
          next unless $x_conv <= $range->[0] and $x_conv >= $range->[1];
        }
      }
      my $bin = $first_bin + $j;
      push @list, [$x_conv, $chunk->{data}->{signal}->{value}->[$j]];
      $last_bin_written = $first_bin + $j;
    }

    if ( $add_zeroes
         and
         $i < $self->{data}->{"peak count"}->{value} - 1
         and
         $last_bin_written < $self->{data}->{chunks}->{value}->[$i+1]->{data}->{"first bin"}->{value} - 1
       ) {
      # add an empty bin following the chunk, unless there is no gap
      # between this and the next chunk
      my $bin = $last_bin_written + 1;
      # $x has been incremented inside the chunk loop
      my $x_conv = exists $self->{converter} ? &{$self->{converter}}($x) + $shift: $x;
      push @list, [$x_conv, 0];
      $last_bin_written++;
    }
  }

  if ( $add_zeroes and $last_bin_written < $self->{data}->{nbins}->{value} - 1 ) {
    # add an empty bin following the last chunk, unless there is no gap
    # left between it and the end of the range ($self->nbins - 1)
    my $x = $start + ($last_bin_written + 1) * $step;
    my $x_conv = exists $self->{converter} ? &{$self->{converter}}($x) + $shift: $x;
    push @list, [$x_conv, 0];
    push @list, [$range->[1], 0] if $add_zeroes;
  }
  return \@list;
}

sub print_bins {
  my ($self, $range, $add_zeroes) = @_;
  my @list;
  my $data = $self->{data};
  my $start = $data->{"first value"}->{value};
  my $step = $data->{step}->{value};
  my $chunks = $data->{chunks}->{value};

  unless ( $range ) {
    unless (exists $self->{converter} ) {
      $range = [$start, $start + $data->{nbins}->{value} * $step];
    }
  }

  print "$range->[0]\t0\n" if $add_zeroes;

  my $shift = 0; # this is declared outside the chunk loop to allow
                 # writing the empty bin following the last chunk with
                 # the same amount of shift as in the last chunk

  foreach my $i ( 0 .. $data->{"peak count"}->{value} - 1 ) { # each chunk
    my $chunk = $chunks->[$i]->{data};
    my $first_bin = $chunk->{"first bin"}->{value};
    $shift = $chunk->{fudge} ? $chunk->{fudge}->{value} : 0;
    my $x = $start + $first_bin * $step;
    my $x_conv = exists $self->{converter} ? &{$self->{converter}}($x) + $shift : $x;

    # print all points in the chunk that fall within the specified range
    foreach my $j ( 0 .. $chunk->{nbins}->{value} - 1) {
      my $x_conv = exists $self->{converter} ? &{$self->{converter}}($x) + $shift : $x;
      $x += $step;
      if ( $range ) {
        if ( exists $self->{converter} ) {
          next unless $x_conv >= $range->[0] and $x_conv <= $range->[1];
        }
        else {
          # frequencies have the reverse order
          next unless $x_conv <= $range->[0] and $x_conv >= $range->[1];
        }
      }
      my $bin = $first_bin + $j;
      print "$x_conv\t" . $chunk->{signal}->{value}->[$j] . "\n";
    }

    if ( $add_zeroes and $i < $data->{"peak count"}->{value} - 1 ) {
      my $from = $chunks->[$i]->first_bin + $chunks->[$i]->{data}->{nbins}->{value};
      my $to = $chunks->[$i+1]->first_bin - 1;
      if ($to >= $from) {
        foreach my $bin ( $from .. $to ) {
          my $x = $start + $bin * $step;
          my $x_conv = exists $self->{converter} ? &{$self->{converter}}($x) + $shift: $x;
          if ( $range ) {
            if ( exists $self->{converter} ) {
              next unless $x_conv >= $range->[0] and $x_conv <= $range->[1];
            }
            else {
              # frequencies have the reverse order
              next unless $x_conv <= $range->[0] and $x_conv >= $range->[1];
            }
          }
          print "$x_conv\t0\n";
        }
      }
    }
  }

  # get the last bin number in the last chunk
  if ( $add_zeroes ) {
    my $last_chunk = $chunks->[$data->{"peak count"}->{value} - 1];
    my $first_trailer_bin = $last_chunk->{data}->{"first bin"}->{value} + $last_chunk->{data}->{nbins}->{value};
    if ( $first_trailer_bin < $data->{nbins}->{value} ) {
      foreach my $bin ( $first_trailer_bin .. $self->{data}->{nbins}->{value} - 1 ) {
        my $x = $start + $bin * $step;
        my $x_conv = exists $self->{converter} ? &{$self->{converter}}($x) + $shift : $x;
        if ( $range ) {
          if ( exists $self->{converter} ) {
            next unless $x_conv >= $range->[0] and $x_conv <= $range->[1];
          }
          else {
            # frequencies have the reverse order
            next unless $x_conv <= $range->[0] and $x_conv >= $range->[1];
          }
        }
        print "$x_conv\t0\n";
      }
    }
    print "$range->[1]\t0\n";
  }
}

1;
__END__

=head1 NAME

Finnigan::Profile -- a full-featured decoder for Finnigan scan profiles

=head1 SYNOPSIS

  use Finnigan;

  say $entry->offset; # returns an offset from the start of scan data stream 
  say $entry->data_size;
  $entry->dump;
  my $profile = Finnigan::Profile->decode( \*INPUT, $packet_header->layout );
  say $profile->first_value;
  say $profile->nchunks;
  say $profile->nbins;
  $profile->set_converter( $converter_function_ref );
  my $bins = $profile->bins; # calls the converter
  my ($mz, $abundance) = @{$bins->[0]} # data in the first bin

=head1 DESCRIPTION

Finningan::Profile is a full-featured decoder for Finnigan scan
profiles. The data it generates contain the seek addresses, sizes and
types of all decoded elements, no matter how small. That makes it very
handy in the exploration of the file format and in writing new code,
but it is not very efficient in production work.


In performance-sensitive applications, the more lightweight
Finnigan::Scan module should be used, which includes
Finnigan::Scan::Profile and other related submodules. It can be used
as a drop-in replacement for the full-featured modules, but it does
not store the seek addresses and object types, greatly reducing the
overhead.

Every scan done in the B<profile mode> has a profile, which
is either a time-domain signal or a frequency spectrum accumulated in
histogram-like bins.


A profile can be either raw or filtered. Filtered profiles are sparse;
they consist of separate data chunks. Each chunk consists of a
contiguous range of bins containing the above-threshold signal. The
bins whose values fall below a cerain threshold are simply discarded,
leaving gaps in the profile -- the reason for the ProfileChunk
structure to exist.

One special case is raw profile, which preserves all data. Since there
are no gaps in a raw profile, it is represented by a single chunk
covering the entire range of bins, so the same container structure is
suitable for complete profiles, as well as for sparse ones.

The bins store the signal intensity, and the bin co-ordinates are
typically the frequencies of Fourier-transformed signal. Since the
bins are equally spaced in the frequency domain, only the first bin
frequency is stored in each profile header. The bin width is common
for all bins and it is also stored in the same header. With these
data, it is possible to calculate the bin values based on the bin
indices.

The programs reading these data must convert the frequencies into the
M/z values using the conversion function specific to the type of
analyser used to acquire the signal. The calibrated coefficients for
this convesion function are stored in the ScanEvent structure (one
instance of this structure exists for every scan).

The B<bins> method of Finnigan::Profile returns the converted bins,
optionally filling the gaps with zeroes.

=head2 METHODS

=over 4

=item decode($stream, $layout)

The constructor method

=item nchunks

Get the number of chunks in the profile

=item nbins

Get the total number of bins in the profile

=item first_value

Get the the value of the first bin in the profile

=item step

Get the bin width and the direction of change (the frequency step
needed to go from one bin to the next is a negative value)

=item chunk, chunks

Get the list of Finnigan::ProfileChunk? objects representing the profile data

=item set_converter($func_ref)

Set the converter function (f -> M/z)

=item set_inverse_converter($func_ref)

Set the inverse converter function (M/z -> f)

=item bins

Get the reference to an array of bin values. Each array element
contains an (_M/z_, abundance) pair.

=item print_bins

List the bin contents to STDOUT

=back

=head1 DEPRECATED

=over 4

=item peak_count

Replaced with B<nchunks>

=back


=head1 SEE ALSO

Finnigan::ProfileChunk

Finnigan::PacketHeader

Finnigan::Scan

Finnigan::Scan::Profile

Finnigan::ScanEvent

Finnigan::ScanIndexEntry

L<uf-scan>


=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
