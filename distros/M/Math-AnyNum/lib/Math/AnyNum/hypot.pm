use 5.014;
use warnings;

our ($ROUND, $PREC);

# hypot(x, y) = sqrt(x^2 + y^2)

sub __hypot__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y)) =~ tr/:/_/rs);

  Math_MPFR__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_hypot($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_MPC: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_abs($r, $y, $ROUND);
        Math::MPFR::Rmpfr_hypot($r, $r, $x, $ROUND);
        return $r;
    }

  Math_MPC__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_abs($r, $x, $ROUND);
        Math::MPFR::Rmpfr_hypot($r, $r, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_MPC: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_abs($r, $x, $ROUND);
        my $t = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_abs($t, $y, $ROUND);
        Math::MPFR::Rmpfr_hypot($r, $r, $t, $ROUND);
        return $r;
    }
}

1;
