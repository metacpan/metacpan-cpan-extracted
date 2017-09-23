use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __pow__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

    #
    ## GMPq
    #
  Math_GMPq__Scalar: {

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_pow_ui($r, $x, CORE::abs($y));

        if ($y < 0) {
            Math::GMPq::Rmpq_sgn($r) || goto &_inf;
            Math::GMPq::Rmpq_inv($r, $r);
        }

        return $r;
    }

  Math_GMPq__Math_GMPq: {

        # Integer power
        if (Math::GMPq::Rmpq_integer_p($y)) {
            $y = Math::GMPq::Rmpq_get_d($y);
            goto Math_GMPq__Scalar;
        }

        # (-x)^(a/b) is a complex number
        if (Math::GMPq::Rmpq_sgn($x) < 0) {
            $x = _mpq2mpc($x);
            $y = _mpq2mpc($y);
            goto Math_MPC__Math_MPC;
        }

        $x = _mpq2mpfr($x);
        $y = _mpq2mpfr($y);

        goto Math_MPFR__Math_MPFR;
    }

  Math_GMPq__Math_GMPz: {
        $y = Math::GMPz::Rmpz_get_d($y);
        goto Math_GMPq__Scalar;
    }

  Math_GMPq__Math_MPFR: {
        $x = _mpq2mpfr($x);
        goto Math_MPFR__Math_MPFR;
    }

  Math_GMPq__Math_MPC: {
        $x = _mpq2mpc($x);
        goto Math_MPC__Math_MPC;
    }

    #
    ## GMPz
    #

  Math_GMPz__Scalar: {

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_pow_ui($r, $x, CORE::abs($y));

        if ($y < 0) {
            Math::GMPz::Rmpz_sgn($r) || goto &_inf;

            my $q = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_z($q, $r);
            Math::GMPq::Rmpq_inv($q, $q);
            return $q;
        }

        return $r;
    }

  Math_GMPz__Math_GMPz: {
        $y = Math::GMPz::Rmpz_get_d($y);
        goto Math_GMPz__Scalar;
    }

  Math_GMPz__Math_GMPq: {

        if (Math::GMPq::Rmpq_integer_p($y)) {
            $y = Math::GMPq::Rmpq_get_d($y);
            goto Math_GMPz__Scalar;
        }

        $x = _mpz2mpfr($x);
        $y = _mpq2mpfr($y);

        goto Math_MPFR__Math_MPFR;
    }

  Math_GMPz__Math_MPFR: {
        $x = _mpz2mpfr($x);
        goto Math_MPFR__Math_MPFR;
    }

  Math_GMPz__Math_MPC: {
        $x = _mpz2mpc($x);
        goto Math_MPC__Math_MPC;
    }

    #
    ## MPFR
    #
  Math_MPFR__Math_MPFR: {

        if (    Math::MPFR::Rmpfr_sgn($x) < 0
            and !Math::MPFR::Rmpfr_integer_p($y)
            and Math::MPFR::Rmpfr_number_p($y)) {
            $x = _mpfr2mpc($x);
            goto Math_MPC__Math_MPFR;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_pow($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Scalar: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        $y < 0
          ? Math::MPFR::Rmpfr_pow_si($r, $x, $y, $ROUND)
          : Math::MPFR::Rmpfr_pow_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPq: {
        $y = _mpq2mpfr($y);
        goto Math_MPFR__Math_MPFR;
    }

  Math_MPFR__Math_GMPz: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_pow_z($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_MPC: {
        $x = _mpfr2mpc($x);
        goto Math_MPC__Math_MPC;
    }

    #
    ## MPC
    #
  Math_MPC__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_pow($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Scalar: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        $y < 0
          ? Math::MPC::Rmpc_pow_si($r, $x, $y, $ROUND)
          : Math::MPC::Rmpc_pow_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_MPFR: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_pow_fr($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPz: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_pow_z($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPq: {
        $y = _mpq2mpc($y);
        goto Math_MPC__Math_MPC;
    }
}

1;
