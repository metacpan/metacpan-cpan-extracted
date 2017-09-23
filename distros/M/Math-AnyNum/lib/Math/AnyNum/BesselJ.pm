use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __BesselJ__ {
    my ($x, $n) = @_;
    goto(join('__', ref($x), ref($n) || 'Scalar') =~ tr/:/_/rs);

  Math_MPFR__Scalar: {
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

        return $r;
    }

  Math_MPFR__Math_GMPz: {

        $n = Math::GMPz::Rmpz_get_d($n);

        # Limit goes to zero when n goes to +/-Infinity
        if (($n < Math::AnyNum::LONG_MIN or $n > Math::AnyNum::ULONG_MAX)
            and Math::MPFR::Rmpfr_number_p($x)) {
            my $r = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_set_ui($r, 0, $ROUND);
            return $r;
        }

        goto Math_MPFR__Scalar;
    }
}

1;
