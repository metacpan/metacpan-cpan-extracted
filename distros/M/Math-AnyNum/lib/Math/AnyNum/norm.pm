use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __norm__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPC: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_norm($r, $x, $ROUND);
        return $r;
    }

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sqr($r, $x, $ROUND);
        return $r;
    }

  Math_GMPz: {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mul($r, $x, $x);
        return $r;
    }

  Math_GMPq: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_mul($r, $x, $x);
        return $r;
    }
}

1;
