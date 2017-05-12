use 5.014;
use warnings;

sub __powmod__ {    # takes three Math::GMPz objects
    my ($x, $y, $z) = @_;

    Math::GMPz::Rmpz_sgn($z) || return;

    if (Math::GMPz::Rmpz_sgn($y) < 0) {
        my $t = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_gcd($t, $x, $z);
        Math::GMPz::Rmpz_cmp_ui($t, 1) == 0 or return;
    }

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_powm($r, $x, $y, $z);
    $r;
}

1;
