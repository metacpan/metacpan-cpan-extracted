use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __inv__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
        return $r;
    }

  Math_GMPq: {

        # Check for division by zero
        Math::GMPq::Rmpq_sgn($x) || do {
            $x = _mpq2mpfr($x);
            goto Math_MPFR;
        };

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_inv($r, $x);
        return $r;
    }

  Math_GMPz: {
        $x = _mpz2mpq($x);
        goto Math_GMPq;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
        return $r;
    }
}

1;
