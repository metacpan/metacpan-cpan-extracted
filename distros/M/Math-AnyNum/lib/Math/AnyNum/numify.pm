use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __numify__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        push @_, $ROUND;

        if (Math::MPFR::Rmpfr_integer_p($x)) {
            if (Math::MPFR::Rmpfr_fits_slong_p($x, $ROUND)) {
                goto &Math::MPFR::Rmpfr_get_si;
            }

            if (Math::MPFR::Rmpfr_fits_ulong_p($x, $ROUND)) {
                goto &Math::MPFR::Rmpfr_get_ui;
            }
        }

        goto &Math::MPFR::Rmpfr_get_d;
    }

  Math_GMPq: {

        if (Math::GMPq::Rmpq_integer_p($x)) {
            @_ = ($x = _mpq2mpz($x));
            goto Math_GMPz;
        }

        goto &Math::GMPq::Rmpq_get_d;
    }

  Math_GMPz: {

        if (Math::GMPz::Rmpz_fits_slong_p($x)) {
            goto &Math::GMPz::Rmpz_get_si;
        }

        if (Math::GMPz::Rmpz_fits_ulong_p($x)) {
            goto &Math::GMPz::Rmpz_get_ui;
        }

        goto &Math::GMPz::Rmpz_get_d;
    }

  Math_MPC: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::RMPC_RE($r, $x);
        @_ = ($x = $r);
        goto Math_MPFR;
    }
}

1;
