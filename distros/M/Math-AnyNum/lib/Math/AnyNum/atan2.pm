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

    # atan2(x, y) = atan(x/y)
  Math_MPC__Math_MPFR: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div_fr($r, $x, $y, $ROUND);
        Math::MPC::Rmpc_atan($r, $r, $ROUND);
        return $r;
    }

    # atan2(x, y) = atan(x/y)
  Math_MPC__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div($r, $x, $y, $ROUND);
        Math::MPC::Rmpc_atan($r, $r, $ROUND);
        return $r;
    }
}

1;
