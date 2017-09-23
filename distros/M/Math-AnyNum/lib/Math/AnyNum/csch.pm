use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __csch__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_csch($r, $x, $ROUND);
        return $r;
    }

    # csch(x) = 1/sinh(x)
  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sinh($r, $x, $ROUND);
        Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
        return $r;
    }
}

1;
