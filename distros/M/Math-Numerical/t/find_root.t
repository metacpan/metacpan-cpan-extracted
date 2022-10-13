use strict;
use warnings;
use utf8;

use Test2::V0;

use Math::Numerical 'find_root', 'solve';

use Carp;
use Readonly;
use Test2::Tools::Compare 'float';

$Carp::Verbose = 1;

Readonly my $PI => 4 * atan2(1, 1);

is($Math::Numerical::_DEFAULT_TOLERANCE, !number(0));
is($Math::Numerical::_DEFAULT_TOLERANCE, float(0.0001, tolerance => 0.0001));

my $tol = $Math::Numerical::_DEFAULT_TOLERANCE;

sub safe_find_root {
  my $ret = eval { find_root(@_) };
  if ($@) {
    print STDERR "$@\n";
  }
  return $ret;
}

is(safe_find_root(\&CORE::cos, 0, 3, do_bracket => 0), float($PI / 2, tolerance => $tol));
is(safe_find_root(\&CORE::cos, 0, 1), float($PI / 2, tolerance => $tol));
is(solve(\&CORE::cos, 0, 1), float($PI / 2, tolerance => $tol));
{
  my @ret = find_root(\&CORE::cos, 0, 1);
  is (\@ret, [float($PI /2, tolerance => $tol), cos($ret[0])]);
}

like(scalar(eval { find_root(\&CORE::cos, 0, 1, do_bracket => 0) }, $@),
     qr/A root must be bracketed in/);

like(scalar(eval { find_root(sub { 1 }, 0, 1) }, $@),
     qr/Can’t bracket a root of the function/);

like(scalar(eval { find_root([1], 0, 1) }, $@),
     qr/The passed \$func is not a code reference \(.*\)/);

like(scalar(eval { find_root(sub { undef }, 0, 1) }, $@),
     qr/The function returned no value/);

like(scalar(eval { find_root(sub { die 'foobar' }, 0, 1) }, $@),
     qr/The function failed: foobar/);

is(safe_find_root(sub { ($_[0] + 3) * ($_[0] - 1) ** 2 }, -4, 0), float(-3, tolerance => $tol));

# Example from https://fr.wikipedia.org/wiki/Taux_effectif_global#Ech%C3%A9ances_mensuelles_constantes_en_fin_de_mois
is(safe_find_root(sub { my $s = -1000; $s += 30.42 / (1 + $_[0] / 100) ** ($_ / 12) for 1..36; $s }, 1, 10), float(6.16, tolerance => 0.01));

{
  sub hard {
    return -1 if $_[0] < 0;
    return $_[0] - 1 if $_[0] < 2;
    return 1 + ($_[0] - 2) * 1e10;
  }
  is(safe_find_root(\&hard, -10, 10), float(1, tolerance => $tol));
  is(safe_find_root(\&hard, -100, 10), float(1, tolerance => $tol));
}
done_testing;
