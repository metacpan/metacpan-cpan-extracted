use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __cmp__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

    #
    ## MPFR
    #
  Math_MPFR__Math_MPFR: {

        if (   Math::MPFR::Rmpfr_nan_p($x)
            or Math::MPFR::Rmpfr_nan_p($y)) {
            return undef;
        }

        return Math::MPFR::Rmpfr_cmp($x, $y);
    }

  Math_MPFR__Math_GMPz: {
        return (
                Math::MPFR::Rmpfr_nan_p($x)
                ? undef
                : Math::MPFR::Rmpfr_cmp_z($x, $y)
               );
    }

  Math_MPFR__Math_GMPq: {
        return (
                Math::MPFR::Rmpfr_nan_p($x)
                ? undef
                : Math::MPFR::Rmpfr_cmp_q($x, $y)
               );
    }

  Math_MPFR__Math_MPC: {
        $x = _mpfr2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_MPFR__Scalar: {
        return (
                  Math::MPFR::Rmpfr_nan_p($x) ? undef
                : ($y || return Math::MPFR::Rmpfr_sgn($x)) < 0 ? Math::MPFR::Rmpfr_cmp_si($x, $y)
                :                                                Math::MPFR::Rmpfr_cmp_ui($x, $y)
               );
    }

    #
    ## GMPq
    #
  Math_GMPq__Math_GMPq: {
        return Math::GMPq::Rmpq_cmp($x, $y);
    }

  Math_GMPq__Math_GMPz: {
        return Math::GMPq::Rmpq_cmp_z($x, $y);
    }

  Math_GMPq__Math_MPFR: {
        return (
                Math::MPFR::Rmpfr_nan_p($y)
                ? undef
                : -Math::MPFR::Rmpfr_cmp_q($y, $x)
               );
    }

  Math_GMPq__Math_MPC: {
        $x = _mpq2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_GMPq__Scalar: {
        return (
                ($y || return Math::GMPq::Rmpq_sgn($x)) < 0
                ? Math::GMPq::Rmpq_cmp_si($x, $y, 1)
                : Math::GMPq::Rmpq_cmp_ui($x, $y, 1)
               );
    }

    #
    ## GMPz
    #
  Math_GMPz__Math_GMPz: {
        return Math::GMPz::Rmpz_cmp($x, $y);
    }

  Math_GMPz__Math_GMPq: {
        return -Math::GMPq::Rmpq_cmp_z($y, $x);
    }

  Math_GMPz__Math_MPFR: {
        return (
                Math::MPFR::Rmpfr_nan_p($y)
                ? undef
                : -Math::MPFR::Rmpfr_cmp_z($y, $x)
               );
    }

  Math_GMPz__Math_MPC: {
        $x = _mpz2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_GMPz__Scalar: {
        return (
                ($y || return Math::GMPz::Rmpz_sgn($x)) < 0
                ? Math::GMPz::Rmpz_cmp_si($x, $y)
                : Math::GMPz::Rmpz_cmp_ui($x, $y)
               );
    }

    #
    ## MPC
    #
  Math_MPC__Math_MPC: {
        my $f = Math::MPFR::Rmpfr_init2($PREC);

        Math::MPC::RMPC_RE($f, $x);
        Math::MPFR::Rmpfr_nan_p($f) && return undef;

        Math::MPC::RMPC_RE($f, $y);
        Math::MPFR::Rmpfr_nan_p($f) && return undef;

        Math::MPC::RMPC_IM($f, $x);
        Math::MPFR::Rmpfr_nan_p($f) && return undef;

        Math::MPC::RMPC_IM($f, $y);
        Math::MPFR::Rmpfr_nan_p($f) && return undef;

        my $si = Math::MPC::Rmpc_cmp($x, $y);
        my $re_cmp = Math::MPC::RMPC_INEX_RE($si);

        return (
                ($re_cmp == 0)
                ? Math::MPC::RMPC_INEX_IM($si)
                : $re_cmp
               );
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
        $y = _any2mpc(_str2obj($y));
        goto Math_MPC__Math_MPC;
    }
}

1;
