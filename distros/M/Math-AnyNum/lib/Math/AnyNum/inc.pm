use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __inc__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_add_ui($r, $x, 1, $ROUND);
        return $r;
    }

  Math_GMPq: {
        state $one = Math::GMPz::Rmpz_init_set_ui_nobless(1);
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_add_z($r, $x, $one);
        return $r;
    }

  Math_GMPz: {
        my $r = Math::GMPz::Rmpz_init_set($x);
        Math::GMPz::Rmpz_add_ui($r, $r, 1);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_add_ui($r, $x, 1, $ROUND);
        return $r;
    }
}

1;
