package Math::Histo::2D;

use strict;
use warnings;
use Math::Histo ();
use Math::Histo::Constants qw(:flags);

our $VERSION = '0.2.0';


sub new {
    my ($class, %args) = @_;
    my $flags = $args{flags} // HISTO_FLAG_NONE;
    $flags |= HISTO_FLAG_TRACK_SUMW2 if $args{sumw2} || $args{track_sumw2};
    $flags |= HISTO_FLAG_EXACT_MOMENTS if $args{exact_moments};

    if (exists $args{xedges} && exists $args{yedges}) {
        return $class->_create_variable($args{xedges}, $args{yedges}, $flags);
    } elsif (exists $args{xbins} && exists $args{xmin} && exists $args{xmax} &&
             exists $args{ybins} && exists $args{ymin} && exists $args{ymax}) {
        return $class->_create_uniform(
            $args{xbins}, $args{xmin}, $args{xmax},
            $args{ybins}, $args{ymin}, $args{ymax},
            $flags
        );
    } else {
        die "Math::Histo::2D->new: missing required binning parameters (specify xbins/xmin/xmax/ybins/ymin/ymax or xedges/yedges)";
    }
}

sub clone {
    my ($self) = @_;
    return $self->_clone;
}

sub from_binary {
    my ($class, $blob) = @_;
    return $class->_deserialize_binary($blob);
}

sub from_json {
    my ($class, $json_str) = @_;
    return $class->_deserialize_json($json_str);
}

sub plot {
    my ($self, %opts) = @_;
    require Math::Histo::CLI;
    require File::Temp;

    my @cmd = ('plot');
    push @cmd, "--style=$opts{style}" if defined $opts{style};
    if (exists $opts{color}) {
        push @cmd, $opts{color} ? '--color=always' : '--color=never';
    }
    push @cmd, "--palette=$opts{palette}" if defined $opts{palette};
    push @cmd, "-w=$opts{width}" if defined $opts{width};
    push @cmd, "-H=$opts{height}" if defined $opts{height};
    push @cmd, '-l' if $opts{log};

    my $tf = File::Temp->new(SUFFIX => '.json', UNLINK => 1);
    print $tf $self->serialize_json;
    close $tf;
    push @cmd, $tf->filename;

    my ($code, $out, $err) = Math::Histo::CLI->capture(@cmd);
    die "Math::Histo::2D::plot failed: $err" if $code != 0 && $err;
    print $out if !defined $opts{show} || $opts{show};
    return $out;
}

use overload
    '+'  => sub { my ($a, $b) = @_; my $c = $a->clone; $c->add($b); $c },
    '-'  => sub { my ($a, $b) = @_; my $c = $a->clone; $c->subtract($b); $c },
    '*'  => sub {
        my ($a, $b, $swap) = @_;
        my $c = $a->clone;
        if (ref($b)) { $c->multiply($b); }
        else { $c->scale($b); }
        $c;
    },
    '/'  => sub {
        my ($a, $b, $swap) = @_;
        my $c = $a->clone;
        if (ref($b)) { $c->divide($b); }
        else { die "Division by zero" if $b == 0; $c->scale(1.0 / $b); }
        $c;
    },
    fallback => 1;

*fill_packed = \&fill_packed_f64;

1;


__END__

=pod

=encoding utf-8

=head1 NAME

Math::Histo::2D - 2-Dimensional Histograms for Math::Histo

=head1 SYNOPSIS

  use Math::Histo::2D;

  # Create uniform 2D histogram (10x5 bins)
  my $h2 = Math::Histo::2D->new(
      xbins => 10, xmin => 0.0, xmax => 10.0,
      ybins => 5,  ymin => 0.0, ymax => 5.0,
      sumw2 => 1,
  );

  # Variable-width 2D grid
  my $h2_var = Math::Histo::2D->new(
      xedges => [0, 1, 5, 10],
      yedges => [0, 2, 4, 6],
  );

  # Fill samples
  $h2->fill(2.5, 1.5);
  $h2->fill(7.5, 3.5, 2.0); # with weight 2.0
  $h2->fill_n([1.0, 2.0, 3.0], [1.0, 2.0, 3.0]);

  # Statistical moments & covariance
  printf("Mean X: %.4f, Mean Y: %.4f\n", $h2->mean_x, $h2->mean_y);
  printf("Covariance: %.4f, Correlation: %.4f\n", $h2->covariance, $h2->correlation);

  # Projections and profiles along axes (returns 1D Math::Histo objects)
  my $proj_x  = $h2->project_x;
  my $proj_y  = $h2->project_y;
  my $prof_x  = $h2->profile_x; # Mean of Y in each X bin with std error

  # Slices across specific bin ranges
  my $slice_x = $h2->slice_x(1, 3); # slice across Y bins [1..3]

  # Serialization
  my $blob = $h2->serialize_binary;
  my $restored = Math::Histo::2D->from_binary($blob);

=head1 DESCRIPTION

C<Math::Histo::2D> provides high-performance two-dimensional histograms with
SIMD-accelerated batch ingestion, 9-region out-of-bounds guards, covariance/correlation
tracking, and 1D projections, slices, and profile histograms.

=head1 CONSTRUCTORS

=over 4

=item B<new(%options)>

Uniform grid: specify C<xbins, xmin, xmax, ybins, ymin, ymax>.

Variable grid: specify C<xedges =E<gt> [...], yedges =E<gt> [...]>.

=item B<clone()>: Deep copy.

=item B<from_binary($blob)>: Deserialize 2D binary format.

=item B<from_json($json)>: Deserialize 2D JSON format.

=back

=head1 METHODS

=over 4

=item B<fill($x, $y, [$weight=1.0])>: Ingest single 2D sample.

=item B<fill_n(\@x, \@y, [\@weights])>: Batch ingest 2D samples from Perl array references.

=item B<fill_packed_f64($packed_x, $packed_y, [$packed_weights])> (or B<fill_packed>): High-performance SIMD zero-copy batch ingestion from packed binary float64 strings (e.g. C<pack('d*', ...)>).

=item B<nx()>, B<ny()>: Number of bins along X and Y axes.


=item B<xmin()>, B<xmax()>: Bounds along X axis.

=item B<ymin()>, B<ymax()>: Bounds along Y axis.

=item B<num_entries()>: Total in-range fill entries.

=item B<total_weight()>: Total in-range accumulated weight.

=item B<mean_x()>, B<mean_y()>: Mean coordinates along axes.

=item B<variance_x()>, B<variance_y()>: Variances along axes.

=item B<covariance()>: Cov(X, Y).

=item B<correlation()>: Pearson correlation coefficient rho_xy in [-1, 1].

=item B<bin_content($ix, $iy)>: Accumulated weight in cell (ix, iy).

=item B<bin_error($ix, $iy)>: Standard error in cell (ix, iy).

=item B<bin_sum_w2($ix, $iy)>: Sum of weights squared in cell (ix, iy).

=item B<project_x()>, B<project_y()>: 1D projection histograms (L<Math::Histo>).

=item B<slice_x($ymin, $ymax)>, B<slice_y($xmin, $xmax)>: 1D slice histograms.

=item B<profile_x()>, B<profile_y()>: 1D profile histograms (mean and std error per bin).

=item B<serialize_binary()>, B<serialize_json()>: Binary and JSON serialization.

=back

=head1 SEE ALSO

=over 4

=item * L<Math::Histo>

=item * L<Alien::libhisto>

=item * C<libhisto> 2D Guide: L<https://github.com/tsee/libhisto/blob/main/docs/histo2d_guide.md>

=back

=head1 AUTHOR

Steffen Mueller E<lt>cpan@steffen-mueller.netE<gt>

=head1 LICENSE

MIT License. Copyright (c) 2026 Steffen Mueller and libhisto contributors.

=cut
