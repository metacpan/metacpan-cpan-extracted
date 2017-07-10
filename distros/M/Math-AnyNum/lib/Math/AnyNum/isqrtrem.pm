use 5.014;
use warnings;

sub __isqrtrem__ {
    my ($x) = @_;

    Math::GMPz::Rmpz_sgn($x) < 0
      and return (_nan(), _nan());

    my $r = Math::GMPz::Rmpz_init();
    my $s = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_sqrtrem($r, $s, $x);
    ($r, $s);
}

1;
