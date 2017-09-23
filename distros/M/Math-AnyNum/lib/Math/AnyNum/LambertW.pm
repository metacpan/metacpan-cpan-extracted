use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __LambertW__ {
    my ($x) = @_;

    my $p = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_set_str($p, '1e-' . CORE::int($PREC >> 2), 10, $ROUND);

    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {

        # Return a complex number for x < -1/e
        if (Math::MPFR::Rmpfr_cmp_d($x, -1 / CORE::exp(1)) < 0) {
            $x = _mpfr2mpc($x);
            goto Math_MPC;
        }

        Math::MPFR::Rmpfr_set_ui((my $r = Math::MPFR::Rmpfr_init2($PREC)), 1, $ROUND);
        Math::MPFR::Rmpfr_set_ui((my $y = Math::MPFR::Rmpfr_init2($PREC)), 0, $ROUND);

        my $count = 0;
        my $tmp   = Math::MPFR::Rmpfr_init2($PREC);

        while (1) {
            Math::MPFR::Rmpfr_sub($tmp, $r, $y, $ROUND);
            Math::MPFR::Rmpfr_cmpabs($tmp, $p) <= 0 and last;

            Math::MPFR::Rmpfr_set($y, $r, $ROUND);

            Math::MPFR::Rmpfr_log($tmp, $r, $ROUND);
            Math::MPFR::Rmpfr_add_ui($tmp, $tmp, 1, $ROUND);

            Math::MPFR::Rmpfr_add($r, $r, $x, $ROUND);
            Math::MPFR::Rmpfr_div($r, $r, $tmp, $ROUND);
            last if ++$count > $PREC;
        }

        Math::MPFR::Rmpfr_log($r, $r, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sqrt($r, $x, $ROUND);
        Math::MPC::Rmpc_add_ui($r, $r, 1, $ROUND);

        my $y = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_ui($y, 0, $ROUND);

        my $tmp = Math::MPC::Rmpc_init2($PREC);
        my $abs = Math::MPFR::Rmpfr_init2($PREC);

        my $count = 0;
        while (1) {
            Math::MPC::Rmpc_sub($tmp, $r, $y, $ROUND);

            Math::MPC::Rmpc_abs($abs, $tmp, $ROUND);
            Math::MPFR::Rmpfr_cmp($abs, $p) <= 0 and last;

            Math::MPC::Rmpc_set($y, $r, $ROUND);

            Math::MPC::Rmpc_log($tmp, $r, $ROUND);
            Math::MPC::Rmpc_add_ui($tmp, $tmp, 1, $ROUND);

            Math::MPC::Rmpc_add($r, $r, $x, $ROUND);
            Math::MPC::Rmpc_div($r, $r, $tmp, $ROUND);
            last if ++$count > $PREC;
        }

        Math::MPC::Rmpc_log($r, $r, $ROUND);
        return $r;
    }
}

1;
