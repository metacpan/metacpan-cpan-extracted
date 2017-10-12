use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __neg__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_neg($r, $x, $ROUND);
        return $r;
    }

  Math_GMPq: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_neg($r, $x);
        return $r;
    }

  Math_GMPz: {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_neg($r, $x);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_neg($r, $x, $ROUND);
        return $r;
    }
}

1;
