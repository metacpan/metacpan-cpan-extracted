use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __cbrt__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {

        # Complex for x < 0
        if (Math::MPFR::Rmpfr_sgn($x) < 0) {
            $x = _mpfr2mpc($x);
            goto Math_MPC;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_cbrt($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {

        state $three_inv = do {
            my $r = Math::MPC::Rmpc_init2_nobless($PREC);
            Math::MPC::Rmpc_set_ui($r, 3, $ROUND);
            Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
            $r;
        };

        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_pow($r, $x, $three_inv, $ROUND);
        return $r;
    }
}

1;
