use 5.014;
use warnings;

our ($ROUND, $PREC);

#
## LOG
#

sub __log__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {

        # Complex for x < 0
        if (Math::MPFR::Rmpfr_sgn($x) < 0) {
            my $r = _mpfr2mpc($x);
            Math::MPC::Rmpc_log($r, $r, $ROUND);
            return $r;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_log($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_log($r, $x, $ROUND);
        return $r;
    }

}

#
## LOG_2
#

sub __log2__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {

        # Complex for x < 0
        if (Math::MPFR::Rmpfr_sgn($x) < 0) {
            $x = _mpfr2mpc($x);
            goto Math_MPC;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_log2($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r   = Math::MPC::Rmpc_init2($PREC);
        my $ln2 = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_const_log2($ln2, $ROUND);
        Math::MPC::Rmpc_log($r, $x, $ROUND);
        Math::MPC::Rmpc_div_fr($r, $r, $ln2, $ROUND);
        return $r;
    }
}

#
## LOG_10
#

sub __log10__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {

        # Complex for x < 0
        if (Math::MPFR::Rmpfr_sgn($x) < 0) {
            $x = _mpfr2mpc($x);
            goto Math_MPC;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_log10($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        state $MPC_VERSION = Math::MPC::MPC_VERSION();

        my $r = Math::MPC::Rmpc_init2($PREC);

        if ($MPC_VERSION >= 65536) {    # available only in mpc>=1.0.0
            Math::MPC::Rmpc_log10($r, $x, $ROUND);
        }
        else {
            my $ln10 = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_set_ui($ln10, 10, $ROUND);
            Math::MPFR::Rmpfr_log($ln10, $ln10, $ROUND);
            Math::MPC::Rmpc_log($r, $x, $ROUND);
            Math::MPC::Rmpc_div_fr($r, $r, $ln10, $ROUND);
        }

        return $r;
    }
}

1;
