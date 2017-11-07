use 5.014;
use warnings;

our ($ROUND, $PREC);

# Implemented as:
#    eta(1) = ln(2)
#    eta(x) = (1 - 2**(1-x)) * zeta(x)

sub __eta__ {
    my ($x) = @_;    # $x is always a Math::MPFR object

    my $r        = Math::MPFR::Rmpfr_init2($PREC);
    my $x_is_int = Math::MPFR::Rmpfr_integer_p($x);

    # Special case for eta(1) = log(2)
    if ($x_is_int and Math::MPFR::Rmpfr_cmp_ui($x, 1) == 0) {
        Math::MPFR::Rmpfr_const_log2($r, $ROUND);
        return $r;
    }

    my $t = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPFR::Rmpfr_ui_sub($r, 1, $x, $ROUND);
    Math::MPFR::Rmpfr_ui_pow($r, 2, $r, $ROUND);
    Math::MPFR::Rmpfr_ui_sub($r, 1, $r, $ROUND);

    if ($x_is_int and Math::MPFR::Rmpfr_fits_ulong_p($x, $ROUND)) {
        Math::MPFR::Rmpfr_zeta_ui($t, Math::MPFR::Rmpfr_get_ui($x, $ROUND), $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_zeta($t, $x, $ROUND);
    }

    Math::MPFR::Rmpfr_mul($r, $r, $t, $ROUND);

    $r;
}

1;
