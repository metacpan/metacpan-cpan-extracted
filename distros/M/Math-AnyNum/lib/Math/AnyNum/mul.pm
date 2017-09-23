use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __mul__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

    #
    ## GMPq
    #
  Math_GMPq__Math_GMPq: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_mul($r, $x, $y);
        return $r;
    }

  Math_GMPq__Math_GMPz: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_mul_z($r, $x, $y);
        return $r;
    }

  Math_GMPq__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_mul_q($r, $y, $x, $ROUND);
        return $r;
    }

  Math_GMPq__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_q($r, $x, $ROUND);
        Math::MPC::Rmpc_mul($r, $r, $y, $ROUND);
        return $r;
    }

    #
    ## GMPz
    #
  Math_GMPz__Math_GMPz: {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mul($r, $x, $y);
        return $r;
    }

  Math_GMPz__Scalar: {
        my $r = Math::GMPz::Rmpz_init();
        $y < 0
          ? Math::GMPz::Rmpz_mul_si($r, $x, $y)
          : Math::GMPz::Rmpz_mul_ui($r, $x, $y);
        return $r;
    }

  Math_GMPz__Math_GMPq: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_mul_z($r, $y, $x);
        return $r;
    }

  Math_GMPz__Math_MPFR: {
        my $f = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_mul_z($f, $y, $x, $ROUND);
        return $f;
    }

  Math_GMPz__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_z($r, $x, $ROUND);
        Math::MPC::Rmpc_mul($r, $r, $y, $ROUND);
        return $r;
    }

    #
    ## MPFR
    #
  Math_MPFR__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_mul($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Scalar: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        $y < 0
          ? Math::MPFR::Rmpfr_mul_si($r, $x, $y, $ROUND)
          : Math::MPFR::Rmpfr_mul_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPq: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_mul_q($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPz: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_mul_z($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_mul_fr($r, $y, $x, $ROUND);
        return $r;
    }

    #
    ## MPC
    #
  Math_MPC__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_mul($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Scalar: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        $y < 0
          ? Math::MPC::Rmpc_mul_si($r, $x, $y, $ROUND)
          : Math::MPC::Rmpc_mul_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_MPFR: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_mul_fr($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPz: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_z($r, $y, $ROUND);
        Math::MPC::Rmpc_mul($r, $r, $x, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPq: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_q($r, $y, $ROUND);
        Math::MPC::Rmpc_mul($r, $r, $x, $ROUND);
        return $r;
    }
}

1;
