package Math::Histo::Fit;

use strict;
use warnings;
use Math::Histo ();
use Math::Histo::Constants qw(:fit);

our $VERSION = '0.2.0';

my %MODEL_STR_MAP = (
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

sub eval {
    my ($class, $model, $params, $x) = @_;
    my $m = (defined $model && exists $MODEL_STR_MAP{lc($model)}) ? $MODEL_STR_MAP{lc($model)} : int($model // 0);
    return $class->eval_model($m, $params, $x);
}

sub eval_grad {
    my ($class, $model, $params, $x) = @_;
    my $m = (defined $model && exists $MODEL_STR_MAP{lc($model)}) ? $MODEL_STR_MAP{lc($model)} : int($model // 0);
    return $class->eval_gradient($m, $params, $x);
}

package Math::Histo::Fit::Result;

use strict;
use warnings;

our $VERSION = '0.2.0';


sub status_str {
    my ($self) = @_;
    my %map = (
        0  => 'CONVERGED_FTOL',
        1  => 'CONVERGED_XTOL',
        2  => 'CONVERGED_GTOL',
        3  => 'CONVERGED_EXACT',
        -1 => 'MAX_ITERATIONS',
        -2 => 'INVALID_ARG',
        -3 => 'SINGULAR_MATRIX',
        -4 => 'DIVERGED',
        -5 => 'NO_DATA',
        -6 => 'NOMEM',
    );
    return $map{$self->status} // 'UNKNOWN';
}

sub summary {
    my ($self) = @_;
    my $p = $self->params;
    my $e = $self->errors;
    my $out = sprintf("Fit Status: %s (iter: %d)\n", $self->status_str, $self->iterations);
    $out .= sprintf("Chi2 / NDF: %.4f / %d (reduced: %.4f, p-value: %.4g)\n",
        $self->chi2, $self->ndf, $self->reduced_chi2, $self->p_value);
    $out .= "Parameters:\n";
    for (my $i = 0; $i < @$p; $i++) {
        $out .= sprintf("  p[%d] = %12.6f +/- %12.6f\n", $i, $p->[$i], $e->[$i]);
    }
    return $out;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Math::Histo::Fit - Curve Fitting Engine and Results for Math::Histo

=head1 SYNOPSIS

  use Math::Histo;

  my $h = Math::Histo->new(bins => 100, min => -5.0, max => 5.0);
  # ... fill data ...

  # Non-linear Gaussian fit via Levenberg-Marquardt
  my $res = $h->fit(
      model    => 'gaussian',
      max_iter => 500,
      tol      => 1e-8,
  );

  if ($res->status >= 0) {
      print $res->summary;
      my $params = $res->params;  # [A, mu, sigma]
      my $errors = $res->errors;  # [sigma_A, sigma_mu, sigma_sigma]
      my $cov    = $res->cov_matrix; # 2D arrayref covariance matrix
      printf("Chi2 / NDF: %.2f / %d (p-value: %.4g)\n", $res->chi2, $res->ndf, $res->p_value);
  }

=head1 DESCRIPTION

C<Math::Histo::Fit> provides non-linear least squares curve fitting using the
Levenberg-Marquardt algorithm with adaptive damping, parameter box constraints,
fixed parameters, and automatic moment-based initial guess heuristics.

Supported Built-in Models:
  - 'gaussian': f(x) = A * exp(-(x - mu)^2 / (2 * sigma^2))
  - 'exponential': f(x) = A * exp(-lambda * x) + C
  - 'polynomial': f(x) = c0 + c1*x + c2*x^2 + ... (direct Linear LS)
  - 'breit_wigner': Breit-Wigner / Cauchy-Lorentz resonance peak
  - 'power_law': f(x) = A * (x - x0)^k
  - 'lognormal': f(x) = (A / (x*sigma*sqrt(2*pi))) * exp(-(ln(x) - mu)^2 / (2*sigma^2))
  - 'gauss_linear': f(x) = A * exp(-(x - mu)^2 / (2*sigma^2)) + c0 + c1*x
  - 'weibull': f(x) = A * (k/lambda) * (x/lambda)^(k-1) * exp(-(x/lambda)^k)
  - 'gamma': f(x) = A * (x^(k-1) * exp(-x/theta)) / (Gamma(k) * theta^k)
  - 'poisson': f(x) = A * (lambda^x * exp(-lambda)) / Gamma(x + 1)
  - 'laplace': f(x) = (A / (2*b)) * exp(-|x - mu| / b)

=head1 Math::Histo::Fit::Result METHODS

=over 4

=item B<status()>: Convergence integer status (>= 0 is success).

=item B<status_str()>: Human-readable status name (e.g. C<CONVERGED_FTOL>, C<CONVERGED_EXACT>).

=item B<iterations()>: Iterations taken.

=item B<n_params()>: Number of parameters.

=item B<params()>: Arrayref of optimal fitted parameter values.

=item B<errors()>: Arrayref of parameter standard errors (sqrt(Cov_ii)).

=item B<cov_matrix()>: 2D arrayref covariance matrix.

=item B<chi2()>: Total Chi-Square value at minimum.

=item B<ndf()>: Degrees of freedom (N_bins - N_free_params).

=item B<reduced_chi2()>: Reduced Chi-Square (chi2 / ndf).

=item B<p_value()>: Goodness-of-fit upper tail probability P(Chi2 >= chi2_obs).

=item B<aic()>, B<bic()>: Akaike and Bayesian Information Criteria.

=item B<summary()>: Formatted multiline diagnostics summary string.

=back

=head1 SEE ALSO

=over 4

=item * L<Math::Histo>

=item * C<libhisto> Curve Fitting Guide: L<https://github.com/tsee/libhisto/blob/main/docs/curve_fitting_guide.md>

=back

=head1 AUTHOR

Steffen Mueller E<lt>cpan@steffen-mueller.netE<gt>

=head1 LICENSE

MIT License. Copyright (c) 2026 Steffen Mueller and libhisto contributors.

=cut
