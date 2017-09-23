use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __boolify__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        return !Math::MPFR::Rmpfr_zero_p($x);
    }

  Math_GMPq: {
        return !!Math::GMPq::Rmpq_sgn($x);
    }

  Math_GMPz: {
        return !!Math::GMPz::Rmpz_sgn($x);
    }

  Math_MPC: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::RMPC_RE($r, $x);
        Math::MPFR::Rmpfr_zero_p($r) || return 1;
        Math::MPC::RMPC_IM($r, $x);
        return !Math::MPFR::Rmpfr_zero_p($r);
    }
}

1;
