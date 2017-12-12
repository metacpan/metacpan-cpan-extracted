use 5.014;
use warnings;

our ($ROUND, $PREC);

#<<<
state $has_z_sub = (Math::MPFR::MPFR_VERSION_MAJOR() == 3
                 && Math::MPFR::MPFR_VERSION_MINOR() >= 1)
                 || Math::MPFR::MPFR_VERSION_MAJOR() > 3;
#>>>

sub __sub__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

    #
    ## GMPq
    #
  Math_GMPq__Math_GMPq: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_sub($r, $x, $y);
        return $r;
    }

  Math_GMPq__Math_GMPz: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_sub_z($r, $x, $y);
        return $r;
    }

  Math_GMPq__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sub_q($r, $y, $x, $ROUND);
        Math::MPFR::Rmpfr_neg($r, $r, $ROUND);
        return $r;
    }

  Math_GMPq__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_q($r, $x, $ROUND);
        Math::MPC::Rmpc_sub($r, $r, $y, $ROUND);
        return $r;
    }

    #
    ## GMPz
    #
  Math_GMPz__Math_GMPz: {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sub($r, $x, $y);
        return $r;
    }

  Math_GMPz__Scalar: {
        my $r = Math::GMPz::Rmpz_init();
        $y < 0
          ? Math::GMPz::Rmpz_add_ui($r, $x, -$y)
          : Math::GMPz::Rmpz_sub_ui($r, $x, $y);
        return $r;
    }

  Math_GMPz__Math_GMPq: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_z_sub($r, $x, $y);
        return $r;
    }

  Math_GMPz__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);

        $has_z_sub
          ? Math::MPFR::Rmpfr_z_sub($r, $x, $y, $ROUND)
          : do {
            Math::MPFR::Rmpfr_sub_z($r, $y, $x, $ROUND);
            Math::MPFR::Rmpfr_neg($r, $r, $ROUND);
          };

        return $r;
    }

  Math_GMPz__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_z($r, $x, $ROUND);
        Math::MPC::Rmpc_sub($r, $r, $y, $ROUND);
        return $r;
    }

    #
    ## MPFR
    #
  Math_MPFR__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sub($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Scalar: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        $y < 0
          ? Math::MPFR::Rmpfr_add_ui($r, $x, -$y, $ROUND)
          : Math::MPFR::Rmpfr_sub_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPq: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sub_q($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPz: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sub_z($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_fr($r, $x, $ROUND);
        Math::MPC::Rmpc_sub($r, $r, $y, $ROUND);
        return $r;
    }

    #
    ## MPC
    #
  Math_MPC__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sub($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Scalar: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        $y < 0
          ? Math::MPC::Rmpc_add_ui($r, $x, -$y, $ROUND)
          : Math::MPC::Rmpc_sub_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_MPFR: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_fr($r, $y, $ROUND);
        Math::MPC::Rmpc_sub($r, $x, $r, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPz: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_z($r, $y, $ROUND);
        Math::MPC::Rmpc_sub($r, $x, $r, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPq: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_q($r, $y, $ROUND);
        Math::MPC::Rmpc_sub($r, $x, $r, $ROUND);
        return $r;
    }
}

1;
