package Math::Histogram;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);
use JSON::XS ();

our $VERSION = '1.04';

require XSLoader;
XSLoader::load('Math::Histogram', $VERSION);

require Math::Histogram::Axis;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
  make_histogram
);

our %EXPORT_TAGS = (
  'all' => \@EXPORT_OK,
);

sub make_histogram {
  my @axises = map Math::Histogram::Axis->new(@$_), @_;
  return Math::Histogram->new(\@axises);
}

sub _from_hash {
  my ($class, $hashref) = @_;
  my $axises_in = $hashref->{axises};
  if (not ref($axises_in) eq 'ARRAY') {
    croak("Need 'axises' hash element as an array reference");
  }
  my $axises = [];
  push @$axises, Math::Histogram::Axis->_from_hash($_) for @$axises_in;
  return $class->_from_hash_internal($hashref, $axises);
}

sub serialize {
  my $self = shift;
  my $hash = $self->_as_hash;
  return JSON::XS::encode_json($hash);
}

sub deserialize {
  my $class = shift;
  my $hash = JSON::XS::decode_json(ref($_[0]) ? ${$_[0]} : $_[0]);
  return $class->_from_hash($hash);
}

1;
__END__

=head1 NAME

Math::Histogram - N-dimensional histogramming library

=head1 SYNOPSIS

  use Math::Histogram;
  my @dimensions = (
    Math::Histogram::Axis->new(10, 0., 1.), # x: 10 bins between 0 and 1
    Math::Histogram::Axis->new([1, 2, 4, 8, 16]), # y: 5 bins of variable size
    Math::Histogram::Axis->new(2, -1., 1.), # z: 2 bins: [-1, 0) and [0, 1)
  );
  my $hist = Math::Histogram->new(\@dimensions);
  # FIXME cover make_histogram here, too
  
  # Fill some primitive data
  while (<>) {
    chomp;
    my @cols = split /\s+/, $_;
    die "Invalid number of columns: " . scalar(@cols)
      if @cols != 3;
    # Insert new datum into histogram
    $hist->fill(\@cols);
  }
  
  # Dump histogram content to screen (excluding overflow)
  for my $iz (1 .. $hist->get_axis(2)->nbins) {
    for my $iy (1 .. $hist->get_axis(1)->nbins) {
      for my $ix (1 .. $hist->get_axis(0)->nbins) {
        print $hist->get_bin_content([$ix, $iy, $iz]), " ";
      }
      print "\n";
    }
    print "\n";
  }

=head1 DESCRIPTION

This Perl module wraps an n-dimensional histogramming library
written in C. 

B<Beware, this is an early release. While the basic functionality is rather
well tested, the library has not been used in production. If you intend to
adopt it for production, please test your application well and get in touch
with the author.>

=head2 On N-Dimensional Histogramming

If all you are looking for is a regular one dimensional
histogram, then consider other libraries such as L<Math::SimpleHisto::XS>
first for simplicity and performance. Some care has been
taken to optimize the library for performance given a variable number
of dimensions, but not knowing the number of dimensions statically
makes for both somewhat inefficient algorithmic implementation as well as
occasionally awkward APIs. For example, simply iterating through all
bins of a 2D histogram -- a matrix -- is as simple as

  # Pseudo-code
  foreach my $ix (0..$nx-1) {
    foreach my $iy (0..$ny-1) {
      my $z = $matrix->get_bin_content([$ix, $iy]);
    }
  }

If you don't know the number of dimensions statically, you need to do something
like this (there are other ways to do it, too):

  # Pseudo-code
  my $coords = [(0) x $ndims];
  foreach my $i (0..$unrolled_total_nbins-1) {
    my $z = $ndimhisto->get_bin_content($coords);

    my $i = 0;
    ++$coords->[$i];
    while ($i < $ndims
           && $coords->[$i] >= $ndimhisto->get_axis($i)->nbins)
    {
      $coords->[$i] = 0;
      ++$coords->[++$i];
    }
  }

Not pretty, eh? Not fast either. So keep that in mind: Your application knows
the number of dimensions that you care about, this histogramming library does not.

=head2 Overview

Generally speaking, a histogram object in the context of this library
contains N axis objects (axises 0 to N-1) that define the binning of each
dimension. Below and above its coordinate range, each axis has an
under- and an overflow bin. When you fill a histogram with data using
the C<fill()> method, and the provided coordinates are outside the
range of the histogram, then the data will be filled into the correct
under- or overflow bin. For example, if you create a 2D histogram with
the following axises:

  my $h = Math::Histogram->new([
    Math::Histogram::Axis->new(2, 0., 1.),
    Math::Histogram::Axis->new(3, 0., 3.),
  ]);

  # Worst ASCII drawing ever:
  # +-+-+-+-+
  # |:|.|.|:|
  # +-+-+-+-+
  # |.| | |.|
  # +-+-+-+-+
  # |.| | |.|  ^
  # +-+-+-+-+  |
  # |.| | |.|  |
  # +-+-+-+-+  dimension 1
  # |:|.|.|:|
  # +-+-+-+-+
  #   ---> dimension 0
  # 
  # Bins marked with . are under- or overflow in one dimension.
  # Bins marked with : are under- or overflow in BOTH dimensions.

Then you created a histogram with six regular bins: two bins in the X direction
and three bins in the Y direction for a total of C<2 * 3 = 6>.
On top of that, you get a ring of over- and underflow bins around your
ordinary bins. In this case, there are a grand total of
14 such over- and underflow bins. As you increase the number of bins in your actual
histogram, the relative number of over- and underflow bins goes down.

You can access histogram content both by the N-dimensional bin numbers (so,
in the 2D example, an array reference containing two integers) or by user
coordinates (eg. an array reference of two floating point numbers). The module
provides facilities to determine the bin in which a particular set of coordinates
falls. The lower boundary of a bin is always considered part of the bin, whereas
the upper boundary is not. Internally, the histogram data is stored in a flat
array since the dimensionality is unknown at compile time. The linear index
into this array is what may be referred to as the "flat" or "linear" bin number.
In a 1D histogram, it corresponds to the bin numbers of the only axis in the
histogram.

=head1 METHODS

=head2 new

Class method, constructor. Takes an array reference as first parameter. The array reference
must contain one or more L<Math::Histogram::Axis> objects that define the binning
in one dimension each. The number of axises determines the dimensionality of the
histogram.

=head2 clone

Returns an exact clone of the histogram.

=head2 new_alike

Returns a clone of the histogram, but without its content.

=head2 get_axis

Given a dimension number (starting at 0), returns the axis object
of that dimension.

=head2 ndim

Returns the number of dimensions in the histogram.

=head2 total

Returns the total content of the histogram. (The sum over all bins,
except this is cached.)

=head2 nfills

Returns the number of fill operations that have been performed on the
histogram so far. This is not the same as total unless all fills have
a weight of 1.

=head2 fill

Given a reference to an array of coordinates, adds 1 to the content
of the bin that the coordinates belong to.

=head2 fill_w

Same as C<fill()>, except that the second argument needs to be a
weight, the number to add to the bin content (instead of incrementing
by 1).

=head2 fill_n

Same as C<fill()>, except that the first parameter needs to be
a reference to a nested array, each of the inner arrays
containing a set of coordinates. In other words, this method works
the same as calling C<fill()> repeatedly for each element in
the outer array:

  my @coords = (
    [0.1, 0.2],
    [3.8, -1.2],
    ...
  );
  
  $h->fill_n(\@coords);
  
  # Is the same as:
  $h->fill($_) for @coords;
  # Except a teeny bit faster.

=head2 fill_nw

This is to C<fill_w(\@coord, $weight)> what C<fill_n(\@coords)> is to C<fill(\@coord)>.
In other words, the first argument is the same as for C<fill_n()>, the second is
an array reference containing as many weights as the first had coordinate sets.

=head2 fill_bin

Same as C<fill()>, but takes an array reference containing bin numbers as argument
(instead of a reference to an array of coordinates).

=head2 fill_bin_w

This is to C<fill_w> what C<fill_bin> is to C<fill>.

=head2 fill_bin_n

This is to C<fill_n> what C<fill_bin> is to C<fill>.

=head2 fill_bin_nw

This is to C<fill_nw> what C<fill_bin> is to C<fill>.

=head2 get_bin_content

Given a reference to an array of bin numbers, returns the content of the
specified bin. Throws an exception when out of bounds.

=head2 find_bin_numbers

Given a reference to an array of coordinates, returns a reference
to an array of (the same number of) bin numbers that correspond to the
bin that the coordinates fall into.

=head2 contract_dimension

Given a dimension number (starting at 0), creates an N-1 dimensional
histogram that contains the original data, but with the specified
dimension contracted. The original histogram is untouched. Throws
an exception if the dimension is out of bounds.

=head2 cumulate

Given a dimension number (starting at 0), cumulates along that dimension,
modifying the input histogram.
Throws an exception if the dimension is out of bounds. Example:

  X ->
  
  1 2 3  ^
  4 5 6  |
  7 8 9  Y

Cumulated along X, the result is:

  1 3  6
  4 9  15
  7 15 24

Cumulated along Y instead, the result is (note direction
of Y axis in example):

  12 15 18
  11 13 15
  7  8  9

=head2 data_equal_to

Given another histogram, returns true if the data content
is equal to the invocant's data. Uses your machine
C<DBL_EPSILON> for floating point comparisons.

=head2 is_overflow_bin

Given a set of bin numbers, returns true if the bin is an under-
or overflow bin, false otherwise. This is O(n) in the number
of dimensions, but O(1) in the number of bins in the histogram.

=head2 is_overflow_bin_linear

Given a linear bin number, returns true if the bin is an under-
or overflow bin, false otherwise. This is O(1) in the number
of dimensions and the number of bins in the histogram.

=head2 serialize

Returns a JSON string that represents this histogram object.

=head2 deserialize

Class method. Given a JSON string as generated by C<serialize()>,
recreates the histogram object that it represents. Also accepts a scalar
reference to a JSON string.

=head1 SEE ALSO

L<Math::Histogram::Axis>, which is part of this distribution,
implements the binning for a histogram in a single dimension.

L<Math::SimpleHisto::XS> is a fast 1D histogramming module.

L<SOOT> is a dynamic wrapper around the ROOT C++ library
which does histogramming and much more. Beware, it is experimental
software.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, 2015 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
