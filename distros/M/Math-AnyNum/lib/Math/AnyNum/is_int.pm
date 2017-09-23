use 5.014;
use warnings;

sub __is_int__ {
    my ($x) = @_;

    goto (ref($x) =~ tr/:/_/rs);

    Math_GMPz: {
        return 1;
    }

    Math_MPFR: {
        goto &Math::MPFR::Rmpfr_integer_p;
    }

    Math_GMPq: {
        goto &Math::GMPq::Rmpq_integer_p;
    }

    Math_MPC: {
        (@_) = _any2mpfr($x);
        goto &Math::MPFR::Rmpfr_integer_p;
    }
}

1;
