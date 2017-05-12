package Math::Symbolic::Custom::ErrorPropagation;

use 5.006;
use strict;
use warnings;
use Carp qw/croak carp cluck confess/;

use Math::Symbolic::Custom::Base;
BEGIN { *import = \&Math::Symbolic::Custom::Base::aggregate_import }

use Math::Symbolic::ExportConstants qw/:all/;
our $VERSION = '0.11';

our $Aggregate_Export = [qw/apply_error_propagation/];

sub apply_error_propagation {
    my ( $f, @elements ) = @_;

    return Math::Symbolic::Constant->zero() if not @elements;

    my $formula;
    foreach my $element (@elements) {
        $formula +=
          Math::Symbolic::Variable->new("sigma_$element")**2 *
          Math::Symbolic::Operator->new( 'partial_derivative', $f,
            Math::Symbolic::Variable->new($element) )**2;
    }
    $formula = sqrt($formula);
    return $formula;
}

1;
__END__

=encoding utf8

=head1 NAME

Math::Symbolic::Custom::ErrorPropagation - Calculate Gaussian Error Propagation

=head1 SYNOPSIS

  use Math::Symbolic qw/parse_from_string/;
  use Math::Symbolic::Custom::ErrorPropagation;
  
  # Force is mass times acceleration.
  my $force = parse_from_string('m*a');
  
  # The measurements of the acceleration and the mass are prone to
  # statistical errors. (Hence have variances themselves.)
  # Thus, the variance in the force is:
  my $variance = $force->apply_error_propagation('a', 'm');
  
  print $variance;
  
  # prints:
  # (
  #   ((sigma_a ^ 2) * ((partial_derivative(m * a, a)) ^ 2)) +
  #   ((sigma_m ^ 2) * ((partial_derivative(m * a, m)) ^ 2))
  # ) ^ 0.5

=head1 DESCRIPTION

This module extends the functionality of Math::Symbolic by offering
facilities to calculate the propagated variance of a function of
variables with variances themselves.

The module adds a method to all Math::Symbolic objects.

=head2 $ms_tree->apply_error_propagation( [list of variable names] )

This method does not modify the Math::Symbolic tree itself, but instead
calculates and returns its variance based on its variable dependencies which
are expected to be passed as arguments to this method in form of a list
of variable names.

The variance is returned as a Math::Symbolic tree itself. It is calculated
using the Gaussian error propagation formula for uncorrelated variances:

  variance( f(x_1, x_2, ..., x_n ) ) =
    sqrt(
      sum_over_i=1_to_n(
        variance(x_i)^2 * (df/dx_i)^2
      )
    )

In the above formula, the derivatives are partial derivatives and the
component variances C<variance(x_i)> are represented as "sigma_x_i" in the
resulting formula. (The "x_i" is replaced by the variable name, though.)

Please refer to the L<SYNOPSIS> for an example.

=head1 AUTHOR

Please send feedback, bug reports, and support requests to one of the
contributors or the Math::Symbolic mailing list.

List of contributors:

  Steffen Müller, symbolic-module at steffen-mueller dot net

=head1 SEE ALSO

New versions of this module can be found on
http://steffen-mueller.net or CPAN.

L<Math::Symbolic>

L<Math::Symbolic::Custom>,
L<Math::Symbolic::Custom::Base>,

=cut

