use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __acsc__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

    # acsc(x) = asin(1/x)
  Math_MPFR: {

        # Return a complex number for x > -1 and x < 1
        if (    Math::MPFR::Rmpfr_cmp_ui($x, 1) < 0
            and Math::MPFR::Rmpfr_cmp_si($x, -1) > 0) {
            $x = _mpfr2mpc($x);
            goto Math_MPC;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
        Math::MPFR::Rmpfr_asin($r, $r, $ROUND);
        return $r;
    }

    # acsc(x) = asin(1/x)
  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
        Math::MPC::Rmpc_asin($r, $r, $ROUND);
        return $r;
    }
}

1;
