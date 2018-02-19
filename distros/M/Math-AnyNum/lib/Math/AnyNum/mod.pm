use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __mod__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

    #
    ## GMPq
    #
  Math_GMPq__Math_GMPq: {

        Math::GMPq::Rmpq_sgn($y)
          || goto &_nan;

        my $quo = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_div($quo, $x, $y);

        # Floor
        Math::GMPq::Rmpq_integer_p($quo) || do {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_set_q($z, $quo);
            Math::GMPz::Rmpz_sub_ui($z, $z, 1) if Math::GMPq::Rmpq_sgn($quo) < 0;
            Math::GMPq::Rmpq_set_z($quo, $z);
        };

        Math::GMPq::Rmpq_mul($quo, $quo, $y);
        Math::GMPq::Rmpq_sub($quo, $x, $quo);

        return $quo;
    }

  Math_GMPq__Math_GMPz: {

        Math::GMPz::Rmpz_sgn($y)
          || goto &_nan;

        my $quo = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_div_z($quo, $x, $y);

        # Floor
        Math::GMPq::Rmpq_integer_p($quo) || do {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_set_q($z, $quo);
            Math::GMPz::Rmpz_sub_ui($z, $z, 1) if Math::GMPq::Rmpq_sgn($quo) < 0;
            Math::GMPq::Rmpq_set_z($quo, $z);
        };

        Math::GMPq::Rmpq_mul_z($quo, $quo, $y);
        Math::GMPq::Rmpq_sub($quo, $x, $quo);

        return $quo;
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
  Math_GMPz__Math_GMPz: {

        if (Math::GMPz::Rmpz_fits_ulong_p($y)) {
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_mod_ui($r, $x, Math::GMPz::Rmpz_get_ui($y) || goto &_nan);
            return $r;
        }

        my $sgn_y = Math::GMPz::Rmpz_sgn($y) || goto &_nan;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mod($r, $x, $y);

        if (!Math::GMPz::Rmpz_sgn($r)) {
            ## ok
        }
        elsif ($sgn_y < 0) {
            Math::GMPz::Rmpz_add($r, $r, $y);
        }

        return $r;
    }

  Math_GMPz__Scalar: {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mod_ui($r, $x, $y);
        return $r;
    }

  Math_GMPz__Math_GMPq: {
        $x = _mpz2mpq($x);
        goto Math_GMPq__Math_GMPq;
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

        my $quo = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_div($quo, $x, $y, $ROUND);
        Math::MPFR::Rmpfr_floor($quo, $quo);
        Math::MPFR::Rmpfr_mul($quo, $quo, $y, $ROUND);
        Math::MPFR::Rmpfr_sub($quo, $x, $quo, $ROUND);

        return $quo;
    }

  Math_MPFR__Scalar: {

        my $quo = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_div_ui($quo, $x, $y, $ROUND);
        Math::MPFR::Rmpfr_floor($quo, $quo);
        Math::MPFR::Rmpfr_mul_ui($quo, $quo, $y, $ROUND);
        Math::MPFR::Rmpfr_sub($quo, $x, $quo, $ROUND);

        return $quo;
    }

  Math_MPFR__Math_GMPq: {

        my $quo = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_div_q($quo, $x, $y, $ROUND);
        Math::MPFR::Rmpfr_floor($quo, $quo);
        Math::MPFR::Rmpfr_mul_q($quo, $quo, $y, $ROUND);
        Math::MPFR::Rmpfr_sub($quo, $x, $quo, $ROUND);

        return $quo;
    }

  Math_MPFR__Math_GMPz: {

        my $quo = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_div_z($quo, $x, $y, $ROUND);
        Math::MPFR::Rmpfr_floor($quo, $quo);
        Math::MPFR::Rmpfr_mul_z($quo, $quo, $y, $ROUND);
        Math::MPFR::Rmpfr_sub($quo, $x, $quo, $ROUND);

        return $quo;
    }

  Math_MPFR__Math_MPC: {
        $x = _mpfr2mpc($x);
        goto Math_MPC__Math_MPC;
    }

    #
    ## MPC
    #
  Math_MPC__Math_MPC: {

        my $quo = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div($quo, $x, $y, $ROUND);

        my $real = Math::MPFR::Rmpfr_init2($PREC);
        my $imag = Math::MPFR::Rmpfr_init2($PREC);

        Math::MPC::RMPC_RE($real, $quo);
        Math::MPC::RMPC_IM($imag, $quo);

        Math::MPFR::Rmpfr_floor($real, $real);
        Math::MPFR::Rmpfr_floor($imag, $imag);

        Math::MPC::Rmpc_set_fr_fr($quo, $real, $imag, $ROUND);

        Math::MPC::Rmpc_mul($quo, $quo, $y, $ROUND);
        Math::MPC::Rmpc_sub($quo, $x, $quo, $ROUND);

        return $quo;
    }

  Math_MPC__Scalar: {

        my $quo = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div_ui($quo, $x, $y, $ROUND);

        my $real = Math::MPFR::Rmpfr_init2($PREC);
        my $imag = Math::MPFR::Rmpfr_init2($PREC);

        Math::MPC::RMPC_RE($real, $quo);
        Math::MPC::RMPC_IM($imag, $quo);

        Math::MPFR::Rmpfr_floor($real, $real);
        Math::MPFR::Rmpfr_floor($imag, $imag);

        Math::MPC::Rmpc_set_fr_fr($quo, $real, $imag, $ROUND);

        Math::MPC::Rmpc_mul_ui($quo, $quo, $y, $ROUND);
        Math::MPC::Rmpc_sub($quo, $x, $quo, $ROUND);

        return $quo;
    }

  Math_MPC__Math_MPFR: {
        $y = _mpfr2mpc($y);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_GMPz: {
        $y = _mpz2mpc($y);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_GMPq: {
        $y = _mpq2mpc($y);
        goto Math_MPC__Math_MPC;
    }
}

1;
