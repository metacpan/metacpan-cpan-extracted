use 5.014;
use warnings;

sub __isqrtrem__ {
    my ($x) = @_;

    Math::GMPz::Rmpz_sgn($x) < 0
      and return (&Math::AnyNum::_nan(), &Math::AnyNum::_nan());

    my $r = Math::GMPz::Rmpz_init();
    my $s = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_sqrtrem($r, $s, $x);
    ($r, $s);
}

1;
