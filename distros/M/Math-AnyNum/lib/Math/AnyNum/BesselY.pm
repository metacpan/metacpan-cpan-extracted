use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __BesselY__ => qw(Math::MPFR Math::GMPz) => sub {
    my ($x, $n) = @_;

    $n = Math::GMPz::Rmpz_get_d($n);

    my $r = Math::MPFR::Rmpfr_init2($PREC);

    if (   $n < Math::AnyNum::LONG_MIN
        or $n > Math::AnyNum::ULONG_MAX) {

        if (Math::MPFR::Rmpfr_sgn($x) < 0 or !Math::MPFR::Rmpfr_number_p($x)) {
            Math::MPFR::Rmpfr_set_nan($r);
            return $r;
        }

        if ($n < 0) {
            Math::MPFR::Rmpfr_set_inf($r, 1);
        }
        else {
            Math::MPFR::Rmpfr_set_inf($r, -1);
        }

        return $r;
    }

    if ($n == 0) {
        Math::MPFR::Rmpfr_y0($r, $x, $ROUND);
    }
    elsif ($n == 1) {
        Math::MPFR::Rmpfr_y1($r, $x, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_yn($r, $n, $x, $ROUND);
    }

    $r;
};

Class::Multimethods::multimethod __BesselY__ => qw(Math::MPFR $) => sub {
    my ($x, $n) = @_;

    my $r = Math::MPFR::Rmpfr_init2($PREC);

    if ($n == 0) {
        Math::MPFR::Rmpfr_y0($r, $x, $ROUND);
    }
    elsif ($n == 1) {
        Math::MPFR::Rmpfr_y1($r, $x, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_yn($r, $n, $x, $ROUND);
    }

    $r;
};

1;
