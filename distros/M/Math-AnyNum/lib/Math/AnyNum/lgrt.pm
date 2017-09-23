use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __lgrt__ {
    my ($c) = @_;

    my $p = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_set_str($p, '1e-' . CORE::int($PREC >> 2), 10, $ROUND);

    goto(ref($c) =~ tr/:/_/rs);

  Math_MPFR: {

        # Return a complex number for x < e^(-1/e)
        if (Math::MPFR::Rmpfr_cmp_d($c, CORE::exp(-1 / CORE::exp(1))) < 0) {
            $c = _mpfr2mpc($c);
            goto Math_MPC;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_log($r, $c, $ROUND);

        Math::MPFR::Rmpfr_set_ui((my $x = Math::MPFR::Rmpfr_init2($PREC)), 1, $ROUND);
        Math::MPFR::Rmpfr_set_ui((my $y = Math::MPFR::Rmpfr_init2($PREC)), 0, $ROUND);

        my $count = 0;
        my $tmp   = Math::MPFR::Rmpfr_init2($PREC);

        while (1) {
            Math::MPFR::Rmpfr_sub($tmp, $x, $y, $ROUND);
            Math::MPFR::Rmpfr_cmpabs($tmp, $p) <= 0 and last;

            Math::MPFR::Rmpfr_set($y, $x, $ROUND);

            Math::MPFR::Rmpfr_log($tmp, $x, $ROUND);
            Math::MPFR::Rmpfr_add_ui($tmp, $tmp, 1, $ROUND);

            Math::MPFR::Rmpfr_add($x, $x, $r, $ROUND);
            Math::MPFR::Rmpfr_div($x, $x, $tmp, $ROUND);
            last if ++$count > $PREC;
        }

        return $x;
    }

  Math_MPC: {
        my $d = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_log($d, $c, $ROUND);

        my $x = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sqrt($x, $c, $ROUND);
        Math::MPC::Rmpc_add_ui($x, $x, 1, $ROUND);
        Math::MPC::Rmpc_log($x, $x, $ROUND);

        my $y = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_ui($y, 0, $ROUND);

        my $tmp = Math::MPC::Rmpc_init2($PREC);
        my $abs = Math::MPFR::Rmpfr_init2($PREC);

        my $count = 0;
        while (1) {
            Math::MPC::Rmpc_sub($tmp, $x, $y, $ROUND);

            Math::MPC::Rmpc_abs($abs, $tmp, $ROUND);
            Math::MPFR::Rmpfr_cmp($abs, $p) <= 0 and last;

            Math::MPC::Rmpc_set($y, $x, $ROUND);

            Math::MPC::Rmpc_log($tmp, $x, $ROUND);
            Math::MPC::Rmpc_add_ui($tmp, $tmp, 1, $ROUND);

            Math::MPC::Rmpc_add($x, $x, $d, $ROUND);
            Math::MPC::Rmpc_div($x, $x, $tmp, $ROUND);
            last if ++$count > $PREC;
        }

        return $x;
    }
}

1;
