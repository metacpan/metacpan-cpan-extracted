use Test2::V0;

use strict;
use warnings;
use utf8;

use Math::Numerical 'find_root';

use Carp;
use Test2::Tools::Compare 'float';

$Carp::Verbose = 1;

use constant PI    => 4 * atan2(1, 1);

is(Math::Numerical::_DEFAULT_TOLERANCE, !number(0));
is(Math::Numerical::_DEFAULT_TOLERANCE, float(0.0001, tolerance => 0.0001));

my $tol = Math::Numerical::_DEFAULT_TOLERANCE;

is(find_root(\&CORE::cos, 0, 3, do_bracket => 0), float(PI / 2, tolerance => $tol));
is(find_root(\&CORE::cos, 0, 1), float(PI / 2, tolerance => 0.00001));

is(find_root(sub { ($_[0] + 3) * ($_[0] - 1) ** 2 }, -4, 0), float(-3, tolerance => $tol));

# Example from https://fr.wikipedia.org/wiki/Taux_effectif_global#Ech%C3%A9ances_mensuelles_constantes_en_fin_de_mois
is(find_root(sub { my $s = -1000; $s += 30.42 / (1 + $_[0] / 100) ** ($_ / 12) for 1..36; $s }, 1, 10), float(6.16, tolerance => 0.01));

done_testing;
