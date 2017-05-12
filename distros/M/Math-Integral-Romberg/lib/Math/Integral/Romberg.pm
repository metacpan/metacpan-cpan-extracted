# -*- perl -*-

package Math::Integral::Romberg;

require Exporter;

use strict;

use vars qw( @ISA @EXPORT @EXPORT_OK );

@ISA       = qw(Exporter);
@EXPORT    = qw();
@EXPORT_OK = qw(integral return_point_count);

use vars qw( $VERSION $abort $return_point_count
	     $rel_err $abs_err $max_split $min_split );

$VERSION = "0.04";

$abort = 0;
$return_point_count = 0;

$rel_err   = 1e-10;
$abs_err   = 1e-20;
$max_split = 16;
$min_split = 5;

=head1 NAME

Math::Integral::Romberg - Scalar numerical integration

=head1 SYNOPSIS

    use Math::Integral::Romberg 'integral';
    sub f { my ($x) = @_; 1/($x ** 2 + 1) } # ... or whatever
    $area = integral(\&f, $x1, $x2);    # Short form
    $area = integral                    # Long form
     (\&f, $x1, $x2, $rel_err, $abs_err, $max_split, $min_split);

    # an alternative way of doing the long form
    $Math::Integral::Romberg::rel_err = $rel_err;
    $Math::Integral::Romberg::abs_err = $abs_err;
    $Math::Integral::Romberg::max_split = $max_split;
    $Math::Integral::Romberg::min_split = $min_split;
    $area = integral(\&f, $x1, $x2);

=head1 DESCRIPTION

integral() numerically estimates the integral of f() using Romberg
integration, a faster relative of Simpson's method.

=head2 Parameters

=over

=item $f

A reference to the function to be integrated.

=item $x1, $x2

The limits of the integration domain. C<&$f(x1)> and C<&$f(x2)> must
be finite.

=item $rel_err

Maximum acceptable relative error. Estimates of relative and absolute
error are based on a comparison of the estimate computed using C<2**n
+ 1> points with the estimate computed using C<2**(n-1) + 1>
points.

Once $min_split has been reached (see below), computation stops as
soon as relative error drops below $rel_err, absolute error drops
below $abs_err, or $max_split is reached.

If not supplied, uses the value B<$Math::Integral::Romberg::rel_err>
whose default is 10**-10. The accuracy limit of double-precision
floating point is about 10**-15.

=item $abs_err

Maximum acceptable absolute error. If not supplied, uses
B<$Math::Integral::Romberg::abs_err>, which defaults to
10**-20.

=item $max_split

At most C<2 ** $max_split + 1> different sample x values are used to
estimate the integral of C<f()>. If not supplied, uses the value
B<$Math::Integral::Romberg::max_split>, which defaults to 16,
corresponding to 65537 sample points.

=item $min_split

At least C<2 ** $min_split + 1> different sample x values are used to
estimate the integral of C<f()>. If not supplied, uses the value of
B<$Math::Integral::Romberg::max_split>, which defaults to 5,
corresponding to 33 sample points.

=item $Math::Integral::Romberg::return_point_count

This value defaults to 0.  If you set it to 1, then when invoked in a
list context, integral() will return a two-element list, containing
the estimate followed by the number of sample points used to compute
the estimate.

=item $Math::Integral::Romberg::abort

This value is set to 1 if neither the $rel_err nor the $abs_err
thresholds are reached before computation stops.  Once set, this
variable remains set until you reset it to 0.

=back

=head2 Default values

Using the long form of integral() sets the convergence parameters
for that call only - you must use the package-qualified variable
names (e.g. $Math::Integral::Romberg::abs_tol) to change the values
for all calls.

=head2 About the Algorithm

Romberg integration uses progressively higher-degree polynomial
approximations each time you double the number of sample points.  For
example, it uses a 2nd-degree polynomial approximation (as Simpson's
method does) after one split (2**1 + 1 sample points), and it uses a
10th-degree polynomial approximation after five splits (2**5 + 1
sample points).  Typically, this will greatly improve accuracy
(compared to simpler methods) for smooth functions, while not making
much difference for badly behaved ones.

=head1 AUTHOR

Eric Boesch (ericboesch@gmail.com)

=cut

sub integral {
  my $return_pts = wantarray && $Math::Integral::Romberg::return_point_count;
  my $abort = \$Math::Integral::Romberg::abort;
  my ($f,$lo,$hi,$rel_err,$abs_err,$max_split,$min_split)=@_;
  ($lo, $hi) = ($hi, $lo) if $lo > $hi;

  $rel_err	||= $Math::Integral::Romberg::rel_err;
  $abs_err	||= $Math::Integral::Romberg::abs_err;
  $max_split	||= $Math::Integral::Romberg::max_split;
  $min_split	||= $Math::Integral::Romberg::min_split;

  my ($estimate, $split, $steps);
  my $step_len = $hi - $lo;
  my $tot = (&$f($lo) + &$f($hi))/2;

  # tot is used to compute the trapezoid approximations.  It is more or
  # less a total of all f() values computed so far.  The trapezoid
  # method assigns half as much weight to f(hi) and f(lo) as it does to
  # all other f() values, so f(hi) and f(lo) are divided by two here.

  my @row = $estimate = $tot * $step_len; # 0th trapezoid approximation.

  for ($split = 1, $steps=2; ; $split++, $step_len /=2, $steps *= 2) {
    my ($x, $new_estimate);

    # Don't let $step_len drop below the limits of numeric precision.
    # (This should prevent infinite loops, but not loss of accuracy.)
    if ($lo + $step_len/$steps == $lo || $hi - $step_len/$steps == $hi) {
      $$abort = 1;
      return $return_pts ? ($estimate, $steps/2 + 1) : $estimate;
    }

    # Compute the (split)th trapezoid approximation.
    for ($x = $lo + $step_len/2; $x < $hi; $x += $step_len) {
      $tot += &$f($x);
    }
    unshift @row, $tot * $step_len / 2;

    # Compute the more refined approximations, based on the (split)th
    # trapezoid approximation and the various (split-1)th refined
    # approximations stored in @row.

    my $pow4 = 4;

    foreach my $td ( 1 .. $split ) {
      $row[$td] = $row[$td-1] +
	($row[$td-1]-$row[$td])/($pow4 - 1);
      $pow4 *= 4;
    }

    # row[0] now contains the (split)th trapezoid approximation,
    # row[1] now contains the (split)th Simpson approximation, and
    # so on up to row[split] which contains the (split)th Romberg
    # approximation.

    # Is this estimate accurate enough?
    $new_estimate = $row[-1];
    if (($split >= $min_split &&
	 (abs($new_estimate - $estimate) < $abs_err ||
	  abs($new_estimate - $estimate) < $rel_err * abs($estimate))) ||
	($split == $max_split && ($$abort = 1))) {
      return $return_pts ? ($new_estimate, $steps + 1) : $new_estimate;
    }
    $estimate = $new_estimate;
  }
}

1;
