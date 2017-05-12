use strict;
use Test::More;
use POSIX;
use Math::Lsoda;

{
  my $solver = Math::Lsoda->new(equation           => \&eqns,
                                initial            => [1.0, 0.0, 0.0],
                                start              => 0.0,
                                end                => 10.0,
                                dt                 => 1,
                               );

  ok(eq_array( \@{$solver->relative_tolerance}, [sqrt(DBL_EPSILON),sqrt(DBL_EPSILON),sqrt(DBL_EPSILON)]), "tolerance test");
  ok(eq_array( \@{$solver->absolute_tolerance}, [sqrt(DBL_EPSILON),sqrt(DBL_EPSILON),sqrt(DBL_EPSILON)]), "tolerance test");

}
sub eqns {
  my ($t, $x, $y) = @_;
  @$y[0] = 1.0e+4 * @$x[1] * @$x[2] - 0.04 * @$x[0];
  @$y[2] = 3.0e+7 * @$x[1] * @$x[1];
  @$y[1] = -(@$y[0] + @$y[2]);
}

done_testing;
