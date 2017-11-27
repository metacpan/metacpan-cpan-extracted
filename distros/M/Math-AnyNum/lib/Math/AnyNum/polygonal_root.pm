use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __polygonal_root__ {
    my ($n, $k, $second) = @_;
    goto(join('__', ref($n), ref($k)) =~ tr/:/_/rs);

    # polygonal_root(n, k)
    #   = ((k - 4) ± sqrt(8 * (k - 2) * n + (k - 4)^2)) / (2 * (k - 2))

  Math_MPFR__Math_MPFR: {
        my $t = Math::MPFR::Rmpfr_init2($PREC);
        my $u = Math::MPFR::Rmpfr_init2($PREC);

        Math::MPFR::Rmpfr_sub_ui($u, $k, 2, $ROUND);    # u = k-2
        Math::MPFR::Rmpfr_mul($t, $n, $u, $ROUND);      # t = n*u
        Math::MPFR::Rmpfr_mul_2ui($t, $t, 3, $ROUND);   # t = t*8

        Math::MPFR::Rmpfr_sub_ui($u, $u, 2, $ROUND);    # u = u-2
        Math::MPFR::Rmpfr_sqr($u, $u, $ROUND);          # u = u^2
        Math::MPFR::Rmpfr_add($t, $t, $u, $ROUND);      # t = t+u

        # Return a complex number for `t < 0`
        if (Math::MPFR::Rmpfr_sgn($t) < 0) {
            $n = _mpfr2mpc($n);
            $k = _mpfr2mpc($k);
            goto Math_MPC__Math_MPC;
        }

        Math::MPFR::Rmpfr_sqrt($t, $t, $ROUND);         # t = sqrt(t)
        Math::MPFR::Rmpfr_sub_ui($u, $k, 4, $ROUND);    # u = k-4

        $second
          ? Math::MPFR::Rmpfr_sub($t, $u, $t, $ROUND)    # t = u-t
          : Math::MPFR::Rmpfr_add($t, $t, $u, $ROUND);   # t = t+u

        Math::MPFR::Rmpfr_add_ui($u, $u, 2, $ROUND);     # u = u+2
        Math::MPFR::Rmpfr_mul_2ui($u, $u, 1, $ROUND);    # u = u*2

        Math::MPFR::Rmpfr_zero_p($u) && return $n;       # `u` is zero
        Math::MPFR::Rmpfr_div($t, $t, $u, $ROUND);       # t = t/u
        return $t;
    }

  Math_MPFR__Math_MPC: {
        $n = _mpfr2mpc($n);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_MPFR: {
        $k = _mpfr2mpc($k);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_MPC: {
        my $t = Math::MPC::Rmpc_init2($PREC);
        my $u = Math::MPC::Rmpc_init2($PREC);

        Math::MPC::Rmpc_sub_ui($u, $k, 2, $ROUND);    # u = k-2
        Math::MPC::Rmpc_mul($t, $n, $u, $ROUND);      # t = n*u
        Math::MPC::Rmpc_mul_2ui($t, $t, 3, $ROUND);   # t = t*8

        Math::MPC::Rmpc_sub_ui($u, $u, 2, $ROUND);    # u = u-2
        Math::MPC::Rmpc_sqr($u, $u, $ROUND);          # u = u^2
        Math::MPC::Rmpc_add($t, $t, $u, $ROUND);      # t = t+u

        Math::MPC::Rmpc_sqrt($t, $t, $ROUND);         # t = sqrt(t)
        Math::MPC::Rmpc_sub_ui($u, $k, 4, $ROUND);    # u = k-4

        $second
          ? Math::MPC::Rmpc_sub($t, $u, $t, $ROUND)    # t = u-t
          : Math::MPC::Rmpc_add($t, $t, $u, $ROUND);   # t = t+u

        Math::MPC::Rmpc_add_ui($u, $u, 2, $ROUND);     # u = u+2
        Math::MPC::Rmpc_mul_2ui($u, $u, 1, $ROUND);    # u = u*2

        if (Math::MPC::Rmpc_cmp_si($t, 0) == 0) {      # `u` is zero
            return $n;
        }

        Math::MPC::Rmpc_div($t, $t, $u, $ROUND);       # t = t/u
        return $t;
    }
}

1;
