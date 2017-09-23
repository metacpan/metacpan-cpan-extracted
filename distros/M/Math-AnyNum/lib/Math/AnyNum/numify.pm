use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __numify__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        push @_, $ROUND;
        goto &Math::MPFR::Rmpfr_get_d;
    }

  Math_GMPq: {
        goto &Math::GMPq::Rmpq_get_d;
    }

  Math_GMPz: {
        goto &Math::GMPz::Rmpz_get_d;
    }

  Math_MPC: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::RMPC_RE($r, $x);
        return Math::MPFR::Rmpfr_get_d($r, $ROUND);
    }
}

1;
