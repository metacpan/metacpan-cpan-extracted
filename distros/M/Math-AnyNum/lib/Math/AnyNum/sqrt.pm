use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __sqrt__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {

        # Complex for x < 0
        if (Math::MPFR::Rmpfr_sgn($x) < 0) {
            my $r = _mpfr2mpc($x);
            Math::MPC::Rmpc_sqrt($r, $r, $ROUND);
            return $r;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sqrt($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sqrt($r, $x, $ROUND);
        return $r;
    }
}

1;
