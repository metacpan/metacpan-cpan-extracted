use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __BesselY__ {
    my ($x, $n) = @_;
    goto(join('__', ref($x), ref($n) || 'Scalar') =~ tr/:/_/rs);

  Math_MPFR__Scalar: {
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

        return $r;
    }

  Math_MPFR__Math_GMPz: {

        $n = Math::GMPz::Rmpz_get_d($n);

        if (   $n < Math::AnyNum::LONG_MIN
            or $n > Math::AnyNum::ULONG_MAX) {

            my $r = Math::MPFR::Rmpfr_init2($PREC);

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

        goto Math_MPFR__Scalar;
    }
}

1;
