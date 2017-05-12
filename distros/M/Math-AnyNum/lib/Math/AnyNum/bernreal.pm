use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __bernreal__ {
    my ($n) = @_;    # $n is an unsigned integer

    if ($n == 0) {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_ui($r, 1, $ROUND);
        return $r;
    }

    if ($n == 1) {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_d($r, 0.5, $ROUND);
        return $r;
    }

    if ($n & 1) {    # Bn = 0 for odd n>1
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_ui($r, 0, $ROUND);
        return $r;
    }

    my $f = Math::MPFR::Rmpfr_init2($PREC);
    my $p = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPFR::Rmpfr_zeta_ui($f, $n, $ROUND);    # f = zeta(n)
    Math::MPFR::Rmpfr_fac_ui($p, $n, $ROUND);     # p = n!
    Math::MPFR::Rmpfr_mul($f, $f, $p, $ROUND);    # f = f * p

    Math::MPFR::Rmpfr_const_pi($p, $ROUND);       # p = PI
    Math::MPFR::Rmpfr_pow_ui($p, $p, $n, $ROUND); # p = p^n

    Math::MPFR::Rmpfr_div_2exp($f, $f, $n - 1, $ROUND);    # f = f / 2^(n-1)

    Math::MPFR::Rmpfr_div($f, $f, $p, $ROUND);             # f = f/p
    Math::MPFR::Rmpfr_neg($f, $f, $ROUND) if $n % 4 == 0;

    $f;
}

1;
