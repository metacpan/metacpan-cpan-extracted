use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __atan2__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y)) =~ tr/:/_/rs);

  Math_MPFR__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_atan2($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_MPC: {
        $x = _mpfr2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_MPFR: {
        $y = _mpfr2mpc($y);
        goto Math_MPC__Math_MPC;
    }

    #
    ## atan2(x, y) = -i * log((y + x*i) / sqrt(x^2 + y^2))
    #
  Math_MPC__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);

        Math::MPC::Rmpc_mul_i($r, $x, 1, $ROUND);
        Math::MPC::Rmpc_add($r, $r, $y, $ROUND);

        my $t1 = Math::MPC::Rmpc_init2($PREC);
        my $t2 = Math::MPC::Rmpc_init2($PREC);

        Math::MPC::Rmpc_sqr($t1, $x, $ROUND);
        Math::MPC::Rmpc_sqr($t2, $y, $ROUND);
        Math::MPC::Rmpc_add($t1, $t1, $t2, $ROUND);
        Math::MPC::Rmpc_sqrt($t1, $t1, $ROUND);

        Math::MPC::Rmpc_div($r, $r, $t1, $ROUND);
        Math::MPC::Rmpc_log($r, $r, $ROUND);
        Math::MPC::Rmpc_mul_i($r, $r, -1, $ROUND);

        return $r;
    }
}

1;
