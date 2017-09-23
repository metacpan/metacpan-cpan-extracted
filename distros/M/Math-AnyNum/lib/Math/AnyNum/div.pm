use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __div__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

    #
    ## GMPq
    #
  Math_GMPq__Math_GMPq: {

        # Check for division by zero
        Math::GMPq::Rmpq_sgn($y) || do {
            $x = _mpq2mpfr($x);
            goto Math_MPFR__Math_GMPq;
        };

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_div($r, $x, $y);
        return $r;
    }

  Math_GMPq__Math_GMPz: {

        # Check for division by zero
        Math::GMPz::Rmpz_sgn($y) || do {
            $x = _mpq2mpfr($x);
            goto Math_MPFR__Math_GMPz;
        };

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_div_z($r, $x, $y);
        return $r;
    }

  Math_GMPq__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_q_div($r, $x, $y, $ROUND);
        return $r;
    }

  Math_GMPq__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_q($r, $x, $ROUND);
        Math::MPC::Rmpc_div($r, $r, $y, $ROUND);
        return $r;
    }

    #
    ## GMPz
    #
  Math_GMPz__Math_GMPz: {

        # Check for division by zero
        Math::GMPz::Rmpz_sgn($y) || do {
            $x = _mpz2mpfr($x);
            goto Math_MPFR__Math_GMPz;
        };

        # Check for exact divisibility
        if (Math::GMPz::Rmpz_divisible_p($x, $y)) {
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_divexact($r, $x, $y);
            return $r;
        }

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_num($r, $x);
        Math::GMPq::Rmpq_set_den($r, $y);
        Math::GMPq::Rmpq_canonicalize($r);
        return $r;
    }

  Math_GMPz__Scalar: {

        # Check for exact divisibility
        if (Math::GMPz::Rmpz_divisible_ui_p($x, CORE::abs($y))) {
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_divexact_ui($r, $x, CORE::abs($y));
            Math::GMPz::Rmpz_neg($r, $r) if $y < 0;
            return $r;
        }

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_ui($r, 1, CORE::abs($y));
        Math::GMPq::Rmpq_set_num($r, $x);
        Math::GMPq::Rmpq_neg($r, $r) if $y < 0;
        Math::GMPq::Rmpq_canonicalize($r);
        return $r;
    }

  Math_GMPz__Math_GMPq: {

        # Check for division by zero
        Math::GMPq::Rmpq_sgn($y) || do {
            $x = _mpz2mpfr($x);
            goto Math_MPFR__Math_GMPq;
        };

        my $q = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_z_div($q, $x, $y);
        return $q;
    }

  Math_GMPz__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_z_div($r, $x, $y, $ROUND);
        return $r;
    }

  Math_GMPz__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_z($r, $x, $ROUND);
        Math::MPC::Rmpc_div($r, $r, $y, $ROUND);
        return $r;
    }

    #
    ## MPFR
    #
  Math_MPFR__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_div($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Scalar: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        $y < 0
          ? Math::MPFR::Rmpfr_div_si($r, $x, $y, $ROUND)
          : Math::MPFR::Rmpfr_div_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPq: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_div_q($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPz: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_div_z($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_fr($r, $x, $ROUND);
        Math::MPC::Rmpc_div($r, $r, $y, $ROUND);
        return $r;
    }

    #
    ## MPC
    #
  Math_MPC__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Scalar: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        if ($y < 0) {
            Math::MPC::Rmpc_div_ui($r, $x, -$y, $ROUND);
            Math::MPC::Rmpc_neg($r, $r, $ROUND);
        }
        else {
            Math::MPC::Rmpc_div_ui($r, $x, $y, $ROUND);
        }
        return $r;
    }

  Math_MPC__Math_MPFR: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div_fr($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPz: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_z($r, $y, $ROUND);
        Math::MPC::Rmpc_div($r, $x, $r, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPq: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_q($r, $y, $ROUND);
        Math::MPC::Rmpc_div($r, $x, $r, $ROUND);
        return $r;
    }
}

1;
