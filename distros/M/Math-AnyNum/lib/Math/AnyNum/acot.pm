use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __acot__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

    # acot(x) = atan(1/x)
  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
        Math::MPFR::Rmpfr_atan($r, $r, $ROUND);
        return $r;
    }

    # acot(x) = atan(1/x)
  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
        Math::MPC::Rmpc_atan($r, $r, $ROUND);
        return $r;
    }
}

1;
