use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __abs__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        Math::MPFR::Rmpfr_sgn($x) >= 0 and return $x;
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_abs($r, $x, $ROUND);
        return $r;
    }

  Math_GMPq: {
        Math::GMPq::Rmpq_sgn($x) >= 0 and return $x;
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_abs($r, $x);
        return $r;
    }

  Math_GMPz: {
        Math::GMPz::Rmpz_sgn($x) >= 0 and return $x;
        my $r = Math::GMPz::Rmpz_init_set($x);
        Math::GMPz::Rmpz_abs($r, $r);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_abs($r, $x, $ROUND);
        return $r;
    }
}

1;
