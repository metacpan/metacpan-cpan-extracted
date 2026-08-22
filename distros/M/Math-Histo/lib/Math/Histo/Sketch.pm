package Math::Histo::Sketch;

use strict;
use warnings;
use Math::Histo ();

our $VERSION = '0.2.0';


sub new {
    my ($class, %args) = @_;
    my $alpha    = $args{alpha} // 0.01;
    my $max_bins = $args{max_bins} // 2048;
    return $class->_create($alpha, $max_bins);
}

sub from_binary {
    my ($class, $blob) = @_;
    return $class->_deserialize_binary($blob);
}

*insert_packed = \&insert_packed_f64;

1;


__END__

=pod

=encoding utf-8

=head1 NAME

Math::Histo::Sketch - DDSketch Bounded-Relative-Error Dynamic Quantile Sketch

=head1 SYNOPSIS

  use Math::Histo::Sketch;

  # Create a sketch guaranteeing <= 1% relative error (alpha = 0.01)
  my $sketch = Math::Histo::Sketch->new(alpha => 0.01, max_bins => 1024);

  # Stream samples
  $sketch->insert(42.5);
  $sketch->insert_w(100.0, 2.5); # with weight 2.5
  $sketch->insert_n([10.5, 20.2, 30.8, 42.1]);

  # Query quantiles
  my $p50  = $sketch->quantile(0.50);
  my $p90  = $sketch->quantile(0.90);
  my $p99  = $sketch->quantile(0.99);
  my $p999 = $sketch->quantile(0.999);

  # Merge sketches across distributed workers
  $sketch->merge($other_sketch);

  # Binary wire format serialization
  my $blob = $sketch->serialize_binary;
  my $restored = Math::Histo::Sketch->from_binary($blob);

=head1 DESCRIPTION

C<Math::Histo::Sketch> implements the B<DDSketch> streaming quantile sketch algorithm
(Masson et al., VLDB 2019). It provides mathematically guaranteed relative error bounds:

  |q_estimated - q_true| / q_true <= alpha

Features:
  - Bounded memory with dynamic collapsing logarithmic binning.
  - Fully mergeable across threads or distributed network nodes.
  - Handles positive numbers, negative numbers, and exact zeros.

=head1 CONSTRUCTORS

=over 4

=item B<new(%options)>

Options:
  - C<alpha>: Target relative error guarantee in (0, 1) (default: 0.01 = 1% relative error).
  - C<max_bins>: Maximum bin budget before collapsing (default: 2048).

=item B<from_binary($blob)>: Deserializes sketch from canonical binary wire format.

=back

=head1 METHODS

=over 4

=item B<insert($value)>: Stream a single sample.

=item B<insert_w($value, $weight)>: Stream a weighted sample.

=item B<insert_n(\@values, [\@weights])>: Stream an array of samples from a Perl array reference.

=item B<insert_packed_f64($packed_values, [$packed_weights])> (or B<insert_packed>): Ingest binary float64 string directly (e.g. C<pack('d*', ...)>).

=item B<quantile($q)>: Query quantile for $q in [0, 1] with alpha relative error.


=item B<merge($other)>: Merge another DDSketch into $sketch in-place.

=item B<min()>: Minimum sample observed.

=item B<max()>: Maximum sample observed.

=item B<total_weight()>: Sum of all sample weights.

=item B<num_entries()>: Total count of insertions.

=item B<reset()>: Reset sketch state to empty.

=item B<serialize_binary()>: Serialize to compact Little-Endian binary byte string.

=back

=head1 SEE ALSO

=over 4

=item * L<Math::Histo>

=item * L<Alien::libhisto>

=back

=head1 AUTHOR

Steffen Mueller E<lt>cpan@steffen-mueller.netE<gt>

=head1 LICENSE

MIT License. Copyright (c) 2026 Steffen Mueller and libhisto contributors.

=cut
