use strict;
use Test::More;
use Math::Lsoda;

open STDERR, ">&STDOUT";
{
  my $solver = Math::Lsoda->new(equation           => \&eqns,
                                initial            => [1.0, 0.0, 0.0],
                                start              => 0.0,
                                end                => 10000.0,
                                dt                 => 100.0,
                                relative_tolerance => [1.0e-14, 1.0e-14, 1.0e-14],
                                absolute_tolerance => [1.0e-14, 1.0e-14, 1.0e-14],
                                filename           => 'file.dat');
  is($solver->run, -1, "excess test");
}

{
  my $solver = Math::Lsoda->new(equation           => \&eqns,
                                initial            => [1.0, 0.0, 0.0],
                                start              => 0.0,
                                end                => 1000.0,
                                dt                 => 1,
                                relative_tolerance => [-1.0e-4, 1.0e-8, 1.0e-4],
                                absolute_tolerance => [1.0e-6, 1.0e-10,1.0e-6],
                                filename           => 'file.dat');

#ok(eq_array( \@{$solver->relative_tolerance}, [sqrt(DBL_EPSILON),sqrt(DBL_EPSILON),sqrt(DBL_EPSILON)]), "eq_array");
#ok(eq_array( \@{$solver->absolute_tolerance}, [sqrt(DBL_EPSILON),sqrt(DBL_EPSILON),sqrt(DBL_EPSILON)]), "eq_array");

  is($solver->run, -3, "illegal test");
}
unlink 'file.dat';

sub eqns {
  my ($t, $x, $y) = @_;
  @$y[0] = 1.0e+4 * @$x[1] * @$x[2] - 0.04 * @$x[0];
  @$y[2] = 3.0e+7 * @$x[1] * @$x[1];
  @$y[1] = -(@$y[0] + @$y[2]);
}

done_testing;
