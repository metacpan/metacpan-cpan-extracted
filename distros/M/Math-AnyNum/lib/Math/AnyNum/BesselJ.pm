use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __BesselJ__ => qw(Math::MPFR Math::GMPz) => sub {
    my ($x, $n) = @_;

    $n = Math::GMPz::Rmpz_get_d($n);

    my $r = Math::MPFR::Rmpfr_init2($PREC);

    # Limit goes to zero when n goes to +/-Infinity
    if (($n < Math::AnyNum::LONG_MIN or $n > Math::AnyNum::ULONG_MAX)
        and Math::MPFR::Rmpfr_number_p($x)) {
        Math::MPFR::Rmpfr_set_ui($r, 0, $ROUND);
        return $r;
    }

    if ($n == 0) {
        Math::MPFR::Rmpfr_j0($r, $x, $ROUND);
    }
    elsif ($n == 1) {
        Math::MPFR::Rmpfr_j1($r, $x, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_jn($r, $n, $x, $ROUND);
    }

    $r;
};

Class::Multimethods::multimethod __BesselJ__ => qw(Math::MPFR $) => sub {
    my ($x, $n) = @_;

    my $r = Math::MPFR::Rmpfr_init2($PREC);

    if ($n == 0) {
        Math::MPFR::Rmpfr_j0($r, $x, $ROUND);
    }
    elsif ($n == 1) {
        Math::MPFR::Rmpfr_j1($r, $x, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_jn($r, $n, $x, $ROUND);
    }

    $r;
};

1;
