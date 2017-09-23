use 5.014;
use warnings;

our ($PREC, $ROUND);

sub __sgn__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        goto &Math::MPFR::Rmpfr_sgn;
    }

  Math_GMPq: {
        goto &Math::GMPq::Rmpq_sgn;
    }

  Math_GMPz: {
        goto &Math::GMPz::Rmpz_sgn;
    }

    # sgn(x) = x / abs(x)
  Math_MPC: {
        my $abs = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_abs($abs, $x, $ROUND);

        if (Math::MPFR::Rmpfr_zero_p($abs)) {    # it's zero
            return 0;
        }

        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div_fr($r, $x, $abs, $ROUND);
        return $r;
    }
}

1;
