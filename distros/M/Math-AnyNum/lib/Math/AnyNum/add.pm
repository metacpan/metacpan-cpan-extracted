use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __add__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

    #
    ## GMPq
    #
  Math_GMPq__Math_GMPq: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_add($r, $x, $y);
        return $r;
    }

  Math_GMPq__Math_GMPz: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_add_z($r, $x, $y);
        return $r;
    }

  Math_GMPq__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_add_q($r, $y, $x, $ROUND);
        return $r;
    }

  Math_GMPq__Math_MPC: {
        my $c = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_q($c, $x, $ROUND);
        Math::MPC::Rmpc_add($c, $c, $y, $ROUND);
        return $c;
    }

    #
    ## GMPz
    #
  Math_GMPz__Math_GMPz: {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_add($r, $x, $y);
        return $r;
    }

  Math_GMPz__Scalar: {
        my $r = Math::GMPz::Rmpz_init();
        $y < 0
          ? Math::GMPz::Rmpz_sub_ui($r, $x, -$y)
          : Math::GMPz::Rmpz_add_ui($r, $x, $y);
        return $r;
    }

  Math_GMPz__Math_GMPq: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_add_z($r, $y, $x);
        return $r;
    }

  Math_GMPz__Math_MPFR: {
        my $f = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_add_z($f, $y, $x, $ROUND);
        return $f;
    }

  Math_GMPz__Math_MPC: {
        my $c = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_z($c, $x, $ROUND);
        Math::MPC::Rmpc_add($c, $c, $y, $ROUND);
        return $c;
    }

    #
    ## MPFR
    #
  Math_MPFR__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_add($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Scalar: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        $y < 0
          ? Math::MPFR::Rmpfr_sub_ui($r, $x, -$y, $ROUND)
          : Math::MPFR::Rmpfr_add_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPq: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_add_q($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPz: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_add_z($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_MPC: {
        my $c = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_add_fr($c, $y, $x, $ROUND);
        return $c;
    }

    #
    ## MPC
    #
  Math_MPC__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_add($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Scalar: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        $y < 0
          ? Math::MPC::Rmpc_sub_ui($r, $x, -$y, $ROUND)
          : Math::MPC::Rmpc_add_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_MPFR: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_add_fr($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPz: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_z($r, $y, $ROUND);
        Math::MPC::Rmpc_add($r, $r, $x, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPq: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_q($r, $y, $ROUND);
        Math::MPC::Rmpc_add($r, $r, $x, $ROUND);
        return $r;
    }
}

1;
