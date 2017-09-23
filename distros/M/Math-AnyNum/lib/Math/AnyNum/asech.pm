use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __asech__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

    # asech(x) = acosh(1/x)
  Math_MPFR: {

        # Return a complex number for x < 0 or x > 1
        if (   Math::MPFR::Rmpfr_cmp_ui($x, 1) > 0
            or Math::MPFR::Rmpfr_cmp_ui($x, 0) < 0) {
            $x = _mpfr2mpc($x);
            goto Math_MPC;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
        Math::MPFR::Rmpfr_acosh($r, $r, $ROUND);
        return $r;
    }

    # asech(x) = acosh(1/x)
  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
        Math::MPC::Rmpc_acosh($r, $r, $ROUND);
        return $r;
    }
}

1;
