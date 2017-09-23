use 5.014;
use warnings;

our ($PREC, $ROUND);

sub __eq__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

    #
    ## MPFR
    #
  Math_MPFR__Math_MPFR: {
        return Math::MPFR::Rmpfr_equal_p($x, $y);
    }

  Math_MPFR__Math_GMPz: {
        return (Math::MPFR::Rmpfr_integer_p($x) and Math::MPFR::Rmpfr_cmp_z($x, $y) == 0);
    }

  Math_MPFR__Math_GMPq: {
        return (Math::MPFR::Rmpfr_number_p($x) and Math::MPFR::Rmpfr_cmp_q($x, $y) == 0);
    }

  Math_MPFR__Math_MPC: {
        $x = _mpfr2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_MPFR__Scalar: {
        return (
                Math::MPFR::Rmpfr_integer_p($x)
                  and (
                       $y < 0
                       ? Math::MPFR::Rmpfr_cmp_si($x, $y)
                       : Math::MPFR::Rmpfr_cmp_ui($x, $y)
                  ) == 0
               );
    }

    #
    ## GMPq
    #
  Math_GMPq__Math_GMPq: {
        return Math::GMPq::Rmpq_equal($x, $y);
    }

  Math_GMPq__Math_GMPz: {
        return (Math::GMPq::Rmpq_integer_p($x) and Math::GMPq::Rmpq_cmp_z($x, $y) == 0);
    }

  Math_GMPq__Math_MPFR: {
        return (Math::MPFR::Rmpfr_number_p($y) and Math::MPFR::Rmpfr_cmp_q($y, $x) == 0);
    }

  Math_GMPq__Math_MPC: {
        $x = _mpq2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_GMPq__Scalar: {
        return (
                Math::GMPq::Rmpq_integer_p($x)
                  and (
                       $y < 0
                       ? Math::GMPq::Rmpq_cmp_si($x, $y, 1)
                       : Math::GMPq::Rmpq_cmp_ui($x, $y, 1)
                  ) == 0
               );
    }

    #
    ## GMPz
    #
  Math_GMPz__Math_GMPz: {
        return (Math::GMPz::Rmpz_cmp($x, $y) == 0);
    }

  Math_GMPz__Math_GMPq: {
        return (Math::GMPq::Rmpq_integer_p($y) and Math::GMPq::Rmpq_cmp_z($y, $x) == 0);
    }

  Math_GMPz__Math_MPFR: {
        return (Math::MPFR::Rmpfr_integer_p($y) and Math::MPFR::Rmpfr_cmp_z($y, $x) == 0);
    }

  Math_GMPz__Math_MPC: {
        $x = _mpz2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_GMPz__Scalar: {
        return (
                (
                 $y < 0
                 ? Math::GMPz::Rmpz_cmp_si($x, $y)
                 : Math::GMPz::Rmpz_cmp_ui($x, $y)
                ) == 0
               );
    }

    #
    ## MPC
    #
  Math_MPC__Math_MPC: {

        my $f1 = Math::MPFR::Rmpfr_init2($PREC);
        my $f2 = Math::MPFR::Rmpfr_init2($PREC);

        Math::MPC::RMPC_RE($f1, $x);
        Math::MPC::RMPC_RE($f2, $y);

        Math::MPFR::Rmpfr_equal_p($f1, $f2) || return 0;

        Math::MPC::RMPC_IM($f1, $x);
        Math::MPC::RMPC_IM($f2, $y);

        return Math::MPFR::Rmpfr_equal_p($f1, $f2);
    }

  Math_MPC__Math_GMPz: {
        $y = _mpz2mpc($y);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_GMPq: {
        $y = _mpq2mpc($y);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_MPFR: {
        $y = _mpfr2mpc($y);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Scalar: {
        my $f = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::RMPC_IM($f, $x);
        Math::MPFR::Rmpfr_zero_p($f) || return 0;
        Math::MPC::RMPC_RE($f, $x);
        $x = $f;
        goto Math_MPFR__Scalar;
    }
}

1;
