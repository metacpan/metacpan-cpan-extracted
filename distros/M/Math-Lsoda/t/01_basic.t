use strict;
use Test::More;
use Math::Lsoda;

{
  my $solver = Math::Lsoda->new(equation           => \&eqns,
                                initial            => [1.0, 0.0, 0.0],
                                start              => 0.0,
                                end                => 100.0,
                                dt                 => 1,
                                relative_tolerance => [1.0e-4, 1.0e-8, 1.0e-4],
                                absolute_tolerance => [1.0e-6, 1.0e-10,1.0e-6],
                                filename           => 'file.dat');

  isa_ok ($solver, 'Math::Lsoda');
  is($solver->run, 2, "run test");
  unlink 'file.dat';
}
sub eqns {
  my ($t, $x, $y) = @_;
  @$y[0] = 1.0e+4 * @$x[1] * @$x[2] - 0.04 * @$x[0];
  @$y[2] = 3.0e+7 * @$x[1] * @$x[1];
  @$y[1] = -(@$y[0] + @$y[2]);
}

done_testing;
