package Math::Histo;

use strict;
use warnings;
use 5.008001;

our $VERSION = '0.2.0';


use XSLoader;
XSLoader::load('Math::Histo', $VERSION);

use Math::Histo::2D;
use Math::Histo::Fit;
use Math::Histo::Sketch;
use Math::Histo::Constants qw(:all);

use overload
    '+'   => \&_op_add,
    '-'   => \&_op_sub,
    '*'   => \&_op_mul,
    '/'   => \&_op_div,
    '""'  => \&_op_stringify,
    bool  => sub { 1 },
    fallback => 1;

sub new {
    my ($class, %args) = @_;
    my $flags = $args{flags} // HISTO_FLAG_NONE;
    $flags |= HISTO_FLAG_TRACK_SUMW2 if $args{sumw2} || $args{track_sumw2};
    $flags |= HISTO_FLAG_EXACT_MOMENTS if $args{exact_moments};

    if (exists $args{edges}) {
        return $class->_create_variable($args{edges}, $flags);
    } elsif (exists $args{bins} || exists $args{nbins}) {
        my $nbins = $args{bins} // $args{nbins};
        my $min   = $args{min}  // 0.0;
        my $max   = $args{max}  // 100.0;
        return $class->_create_uniform($nbins, $min, $max, $flags);
    } else {
        die "Math::Histo->new: specify 'bins', 'min', 'max' for uniform binning, or 'edges' => [...] for variable binning";
    }
}

my %RULE_MAP = (
    auto    => 0,
    fd      => 1,
    scott   => 2,
    sturges => 3,
    doane   => 4,
    knuth   => 5,
);

sub create_auto {
    my ($class, $samples, %args) = @_;
    my $rule_str = lc($args{rule} // 'auto');
    my $rule = exists $RULE_MAP{$rule_str} ? $RULE_MAP{$rule_str} : int($rule_str);
    my $flags = $args{flags} // 0;
    $flags |= 1 if $args{sumw2} || $args{track_sumw2};
    $flags |= 2 if $args{exact_moments};
    return $class->_create_auto($samples, $rule, $flags);
}

sub estimate_bins {
    my ($class, $samples, $rule_arg) = @_;
    my $rule_str = lc($rule_arg // 'auto');
    my $rule = exists $RULE_MAP{$rule_str} ? $RULE_MAP{$rule_str} : int($rule_str);
    return $class->_estimate_bins($samples, $rule);
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

sub from_file {
    my ($class, $path) = @_;
    open my $fh, '<:raw', $path or die "Math::Histo::from_file: cannot open '$path': $!";
    my $data = do { local $/; <$fh> };
    close $fh;

    # If first 6 bytes match binary magic ("\x89LHIST" or "\x89LH2D"), deserialize binary, else JSON
    if (substr($data, 0, 6) eq "\x89LHIST" || substr($data, 0, 6) eq "\x89LH2D") {
        return $class->from_binary($data);
    } else {
        return $class->from_json($data);
    }
}

sub write_file {
    my ($self, $path, %opts) = @_;
    my $format = lc($opts{format} // 'binary');
    my $data = ($format eq 'json') ? $self->serialize_json($opts{pretty} // 1) : $self->serialize_binary;
    open my $fh, '>:raw', $path or die "Math::Histo::write_file: cannot open '$path' for writing: $!";
    print $fh $data;
    close $fh;
    return 1;
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
    push @cmd, '-S' if $opts{sparkline};
    push @cmd, "-w=$opts{width}" if defined $opts{width};
    push @cmd, "-H=$opts{height}" if defined $opts{height};
    push @cmd, '-l' if $opts{log};
    push @cmd, '-e' if $opts{errors};
    push @cmd, "--fit=$opts{fit}" if defined $opts{fit};
    push @cmd, '--kde' if $opts{kde};
    push @cmd, '--cdf' if $opts{cdf};

    my $tf = File::Temp->new(SUFFIX => '.json', UNLINK => 1);
    print $tf $self->serialize_json;
    close $tf;
    push @cmd, $tf->filename;

    my ($code, $out, $err) = Math::Histo::CLI->capture(@cmd);
    die "Math::Histo::plot failed: $err" if $code != 0 && $err;
    print $out if !defined $opts{show} || $opts{show};
    return $out;
}

sub sparkline {
    my ($self, %opts) = @_;
    return $self->plot(%opts, sparkline => 1);
}

sub top {
    my ($self, @args) = @_;
    require Math::Histo::CLI;
    return Math::Histo::CLI->run('top', @args);
}

sub fit {
    my ($self, %args) = @_;
    my $model_str = lc($args{model} // 'gaussian');
    my %model_map = (
        gaussian     => HISTO_FIT_GAUSSIAN,
        gauss        => HISTO_FIT_GAUSSIAN,
        exponential  => HISTO_FIT_EXPONENTIAL,
        exp          => HISTO_FIT_EXPONENTIAL,
        polynomial   => HISTO_FIT_POLYNOMIAL,
        poly         => HISTO_FIT_POLYNOMIAL,
        breit_wigner => HISTO_FIT_BREIT_WIGNER,
        cauchy       => HISTO_FIT_BREIT_WIGNER,
        power_law    => HISTO_FIT_POWER_LAW,
        powerlaw     => HISTO_FIT_POWER_LAW,
        lognormal    => HISTO_FIT_LOG_NORMAL,
        log_normal   => HISTO_FIT_LOG_NORMAL,
        gauss_linear => HISTO_FIT_GAUSSIAN_PLUS_LINEAR,
        gauss_poly1  => HISTO_FIT_GAUSSIAN_PLUS_LINEAR,
        weibull      => HISTO_FIT_WEIBULL,
        gamma        => HISTO_FIT_GAMMA,
        erlang       => HISTO_FIT_GAMMA,
        poisson      => HISTO_FIT_POISSON,
        laplace      => HISTO_FIT_LAPLACE,
    );

    die "Math::Histo::fit: unknown model '$model_str'" unless exists $model_map{$model_str};
    my $model_type = $model_map{$model_str};

    my $initial = $args{initial} // $args{initial_params};
    my $lower   = $args{lower_bounds} // $args{lower};
    my $upper   = $args{upper_bounds} // $args{upper};
    my $fixed   = $args{fixed} // $args{fixed_mask};
    my $max_iter = $args{max_iter} // $args{max_iterations} // 200;
    my $tol     = $args{tol} // 1e-8;
    my $loss    = $args{mle} ? HISTO_FIT_LOSS_POISSON_MLE : HISTO_FIT_LOSS_CHI2;

    return Math::Histo::Fit->_fit_builtin(
        $self, $model_type, $initial, $lower, $upper, $fixed, $max_iter, $tol, $loss
    );
}

sub _op_add {
    my ($a, $b, $swap) = @_;
    my $res = $a->clone;
    $res->add($b) or die "Math::Histo: addition failed (incompatible binning)";
    return $res;
}

sub _op_sub {
    my ($a, $b, $swap) = @_;
    if ($swap) {
        my $res = $b->clone;
        $res->subtract($a) or die "Math::Histo: subtraction failed";
        return $res;
    }
    my $res = $a->clone;
    $res->subtract($b) or die "Math::Histo: subtraction failed";
    return $res;
}

sub _op_mul {
    my ($a, $b, $swap) = @_;
    if (!ref($b)) {
        my $res = $a->clone;
        $res->scale($b) or die "Math::Histo: scalar multiplication failed";
        return $res;
    }
    my $res = $a->clone;
    $res->multiply($b) or die "Math::Histo: histogram multiplication failed";
    return $res;
}

sub _op_div {
    my ($a, $b, $swap) = @_;
    if (!ref($b)) {
        die "Math::Histo: division by zero" if $b == 0;
        my $res = $a->clone;
        $res->scale(1.0 / $b) or die "Math::Histo: scalar division failed";
        return $res;
    }
    my $res = $a->clone;
    $res->divide($b) or die "Math::Histo: histogram division failed";
    return $res;
}

sub _op_stringify {
    my ($self) = @_;
    return sprintf("Math::Histo[bins=%d, range=[%.4g, %.4g], entries=%d, mean=%.4g, sd=%.4g]",
        $self->nbins, $self->min, $self->max, $self->num_entries, $self->mean, $self->std_dev);
}

*fill_packed = \&fill_packed_f64;

1;


__END__

=pod

=encoding utf-8

=head1 NAME

Math::Histo - Fast, memory-safe C histogramming and statistical computing for Perl

=head1 SYNOPSIS

  use Math::Histo;

  # Uniform 1D histogram (50 bins in [0, 100], tracking sum(w^2))
  my $h = Math::Histo->new(bins => 50, min => 0.0, max => 100.0, sumw2 => 1);

  # Variable-width binning
  my $h_var = Math::Histo->new(edges => [0.0, 1.0, 5.0, 10.0, 50.0, 100.0]);

  # Ingestion: scalar, batch arrayref, or packed binary doubles
  $h->fill(42.5);
  $h->fill(84.0, 2.5); # with weight 2.5
  $h->fill_n([10.5, 20.2, 30.8, 42.1]);
  $h->fill_packed_f64($packed_doubles_scalar);

  # Statistical summaries
  printf("Entries: %d, Total Weight: %.2f\n", $h->num_entries, $h->total_weight);
  printf("Mean: %.4f +/- %.4f\n", $h->mean, $h->std_dev);
  printf("Median: %.4f (IQR: %.4f, MAD: %.4f)\n", $h->median, $h->iqr, $h->mad);
  printf("Skewness: %.4f, Excess Kurtosis: %.4f\n", $h->skewness, $h->excess_kurtosis);

  # Continuous peak detection
  my $mode = $h->mode;
  printf("Continuous Mode: %.4f (FWHM: %.4f, RMS: %.4f)\n", $mode, $h->fwhm, $h->rms);

  # Non-linear curve fitting (Levenberg-Marquardt)
  my $fit = $h->fit(model => 'gaussian');
  print $fit->summary;

  # Operator overloading
  my $h2 = $h * 2.0;
  my $sum = $h + $h2;
  print "$h\n"; # stringification

  # Two-sample hypothesis testing & distance metrics
  my ($chi2, $ndf) = $h->chi2_test($h2);
  my $ks   = $h->kolmogorov_smirnov($h2);
  my $w1   = $h->wasserstein_distance($h2);
  my $bhat = $h->bhattacharyya_distance($h2);
  my $kl   = $h->kl_divergence($h2);

  # Zero-loss binary wire format and JSON serialization
  my $blob = $h->serialize_binary;
  my $restored = Math::Histo->from_binary($blob);
  $h->write_file('data.histo', format => 'binary');

=head1 DESCRIPTION

C<Math::Histo> is a high-performance Perl XS wrapper for the C<libhisto> C library.
It provides SIMD-accelerated 1D and 2D histogramming, online Welford statistical moments,
non-linear curve fitting (Levenberg-Marquardt), and streaming dynamic quantile sketches (DDSketch).

=head1 CONSTRUCTORS

=over 4

=item B<new(%options)>

Creates a new 1D histogram.

Uniform binning options:
  bins => $count (or nbins => $count)
  min  => $min_val (default: 0.0)
  max  => $max_val (default: 100.0)

Variable binning options:
  edges => [ $e0, $e1, $e2, ... ] (strictly monotonically increasing)

Feature flags:
  sumw2         => 1 (track per-bin sum of weights squared for error propagation)
  exact_moments => 1 (track running mean/variance during fill operations)

=item B<clone()>

Creates an exact deep copy of the histogram.

=item B<from_binary($byte_string)>

Deserializes a histogram from canonical Little-Endian binary format.

=item B<from_json($json_string)>

Deserializes a histogram from a JSON string.

=item B<from_file($filename)>

Autodetects format (binary wire format or JSON) and loads the histogram from disk.

=back

=head1 INGESTION METHODS

=over 4

=item B<fill($x, [$weight=1.0])>

Fills a single coordinate with optional weight. Returns 1 on success, 0 on non-finite rejection.

=item B<fill_n(\@x, [\@weights])>

Batch fills an arrayref of coordinates and optional weights.

=item B<fill_packed_f64($packed_x, [$packed_w])> (or B<fill_packed>)

High-performance zero-copy batch fill from raw packed 64-bit IEEE double scalars (e.g. C<pack("d*", ...)> or C<PDL::get_dataref>).


=item B<reset()>

Resets all bin contents, moments, and out-of-range counters to zero.

=back

=head1 BIN ACCESS & GEOMETRY

=over 4

=item B<nbins()>: Number of bins.

=item B<min()>: Lower range boundary.

=item B<max()>: Upper range boundary.

=item B<is_uniform()>: Returns 1 if uniform binning, 0 if variable-width binning.

=item B<bin_content($idx)>: Accumulated weight in bin $idx (0-indexed).

=item B<bin_error($idx)>: Standard error in bin $idx (sqrt(sum_w2) or sqrt(content)).

=item B<bin_sum_w2($idx)>: Sum of weights squared in bin $idx.

=item B<bin_low_edge($idx)>: Lower edge coordinate of bin $idx.

=item B<bin_high_edge($idx)>: Upper edge coordinate of bin $idx.

=item B<bin_center($idx)>: Geometric center coordinate of bin $idx.

=item B<bin_width($idx)>: Width of bin $idx.

=item B<bin_contents()>: Returns an arrayref of all bin contents.

=item B<bin_edges()>: Returns an arrayref of all bin edges (length nbins + 1).

=item B<find_bin($x)>: Returns the 0-indexed bin index for coordinate $x (-1 for underflow, nbins for overflow).

=item B<underflow_weight()>: Total weight accumulated below min.

=item B<overflow_weight()>: Total weight accumulated above max.

=item B<nan_count()>: Total count of non-finite (NaN) samples rejected.

=back

=head1 STATISTICAL ANALYSIS

=over 4

=item B<num_entries()>: Total number of in-range fill operations.

=item B<total_weight()>: Total accumulated in-range weight sum.

=item B<mean()>: Sample mean.

=item B<variance()>: Sample variance.

=item B<std_dev()>: Sample standard deviation.

=item B<skewness()>: Distribution skewness (gamma_1).

=item B<kurtosis()>: Distribution kurtosis (beta_2).

=item B<excess_kurtosis()>: Excess kurtosis (gamma_2 = beta_2 - 3).

=item B<central_moment($order)>: Central statistical moment of given order.

=item B<median()>: Estimated median (50th percentile).

=item B<quantile($p)>: Continuous piecewise linear quantile for $p in [0, 1].

=item B<iqr()>: Interquartile Range (Q75 - Q25).

=item B<mad()>: Median Absolute Deviation from median.

=item B<mode()>: Continuous mode peak coordinate estimated via parabolic interpolation.

=item B<fwhm()>: Full Width at Half Maximum of dominant peak.

=item B<rms()>: Root Mean Square: sqrt(M2 + mean^2).

=item B<trimmed_mean($fraction)>: Trimmed mean excluding tails.

=item B<winsorized_mean($fraction)>: Winsorized mean replacing tails with quantile thresholds.

=item B<integral()>: Total integrated sum of bin weights.

=item B<cdf([$prenormalization=1.0])>: Returns a new C<Math::Histo> object representing the cumulative distribution function.

=item B<stats()>: Returns a hashref containing complete summary statistics.

=back

=head1 ARITHMETIC & TRANSFORMATIONS

=over 4

=item B<scale($factor)>: In-place scalar multiplication.

=item B<normalize([$target_area=1.0])>: In-place normalization.

=item B<rebin($factor)>: Returns a new histogram with adjacent uniform bins combined.

=item B<add($other)>, B<subtract($other)>, B<multiply($other)>, B<divide($other)>: In-place element-wise arithmetic.

=item Overloaded operators: C<+>, C<->, C<*>, C</>, C<"">.

=back

=head1 TWO-SAMPLE DISTANCE METRICS

=over 4

=item B<chi2_test($other)>: Returns C<($chi2, $ndf)>.

=item B<kolmogorov_smirnov($other)>: Two-sample Kolmogorov-Smirnov supremum distance.

=item B<wasserstein_distance($other)>: 1D Earth Mover's Distance (L1 CDF integral).

=item B<kl_divergence($other)>: Kullback-Leibler divergence D_KL(self || other).

=item B<bhattacharyya_distance($other)>: Bhattacharyya distance between distributions.

=back

=head1 CURVE FITTING

=over 4

=item B<fit(%args)>

Fits a parametric model to the histogram using the Levenberg-Marquardt non-linear optimizer.

Parameters:
  model   => 'gaussian' | 'exponential' | 'polynomial' | 'breit_wigner' | 'power_law'
  initial => [ ... ] (optional initial guesses, auto-estimated if omitted)
  lower   => [ ... ] (optional lower parameter bounds)
  upper   => [ ... ] (optional upper parameter bounds)
  fixed   => [ 0, 1, ... ] (optional boolean flags to freeze specific parameters)
  max_iter => 200 (maximum iterations)
  tol     => 1e-8 (relative tolerance)
  mle     => 1 (use Poisson MLE deviance instead of Chi2)

Returns a L<Math::Histo::Fit::Result> object.

=back

=head1 SERIALIZATION

=over 4

=item B<serialize_binary()>: Returns scalar byte string in canonical Little-Endian wire format.

=item B<serialize_json([$pretty=0])>: Returns JSON string representation.

=item B<write_file($path, [format => 'binary'|'json'])>: Writes histogram directly to disk.

=back

=head1 PERFORMANCE & BENCHMARKS

C<Math::Histo> leverages C99 core algorithms, cache-conscious memory layout, and runtime-detected AVX2 / AVX-512 / ARM NEON vector instructions. While individual method invocations incur standard Perl XS sub-call overhead (~50 ns), bulk ingestion methods (C<fill_n> and C<fill_packed_f64>) bypass Perl interpreter loop overhead to achieve throughput exceeding B<450+ Million operations/second>.

Benchmark measured on an Intel(R) Core(TM) Ultra 7 255HX (Linux x86_64, Perl 5.40):

  +---------------------------------+--------------+------------+----------------+------------+
  | Benchmark Operation             | Count        | Time       | Throughput     | Latency    |
  +=================================+==============+============+================+============+
  | 1D Uniform Fill (method call)   |  2,000,000 ops|    0.099 s |   20.28 Mops/s | 49.3 ns/op |
  | 1D Weighted Fill + sumw2        |  2,000,000 ops|    0.103 s |   19.35 Mops/s | 51.7 ns/op |
  | 1D Variable Bins (100 bins)     |  2,000,000 ops|    0.156 s |   12.79 Mops/s | 78.2 ns/op |
  | 1D Batch Arrayref (fill_n)      |  2,000,000 ops|    0.033 s |   61.02 Mops/s | 16.4 ns/op |
  | 1D Packed f64 Buffer (SIMD)     |  5,000,000 ops|    0.011 s |  454.46 Mops/s |  2.20 ns/op|
  | 2D Uniform Fill (method call)   |  2,000,000 ops|    0.109 s |   18.38 Mops/s | 54.4 ns/op |
  | 2D Packed f64 Buffer (SIMD)     |  5,000,000 ops|    0.018 s |  281.26 Mops/s |  3.56 ns/op|
  | DDSketch Dynamic Insert         |  2,000,000 ops|    0.121 s |   16.47 Mops/s | 60.7 ns/op |
  | DDSketch Packed Buffer          |  5,000,000 ops|    0.067 s |   74.21 Mops/s | 13.48 ns/op|
  +---------------------------------+--------------+------------+----------------+------------+

To run the benchmark suite on your machine:

  perl -Iblib/lib -Iblib/arch bench/bench_fill.pl

=head1 IN-DEPTH DOCUMENTATION & ALGORITHMIC COMPLEXITY


For detailed documentation on underlying algorithms, mathematical proofs, IEEE-754 numerical behavior, SIMD vectorization kernels, and asymptotic time/space complexity tables, please refer to the main C library manual:

=over 4

=item * B<HTML Manual & Architecture Guides>: L<https://github.com/tsee/libhisto>

=item * B<Serialization Wire Format Specification>: L<https://github.com/tsee/libhisto/blob/main/docs/serialization_format.md>

=item * B<Statistical Formulae & Derivations>: L<https://github.com/tsee/libhisto/blob/main/docs/statistical_formulae.md>

=item * B<Curve Fitting Guide>: L<https://github.com/tsee/libhisto/blob/main/docs/curve_fitting_guide.md>

=back

=head1 SEE ALSO

=over 4

=item * L<Math::Histo::2D> - 2-Dimensional Histograms with Projections and Slices

=item * L<Math::Histo::Fit> - Non-Linear Curve Fitting Engine

=item * L<Math::Histo::Sketch> - DDSketch Relative-Error Streaming Quantile Sketches

=item * L<Math::Histo::Constants> - Status Codes and Feature Flags

=item * L<Alien::libhisto> - libhisto C Library Provider

=back

=head1 AUTHOR

Steffen Mueller E<lt>cpan@steffen-mueller.netE<gt>

=head1 LICENSE

MIT License. Copyright (c) 2026 Steffen Mueller and libhisto contributors.

=cut
