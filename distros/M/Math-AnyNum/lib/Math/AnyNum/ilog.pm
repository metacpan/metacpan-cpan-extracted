use 5.014;
use warnings;

sub __ilog__ {
    my ($x, $y) = @_;

    # ilog(x, y <= 1) = NaN
    Math::GMPz::Rmpz_cmp_ui($y, 1) <= 0 and goto &_nan;

    # ilog(x <= 0, y) = NaN
    Math::GMPz::Rmpz_sgn($x) <= 0 and goto &_nan;

    # Return faster for y <= 62
    if (Math::GMPz::Rmpz_cmp_ui($y, 62) <= 0) {

        $y = Math::GMPz::Rmpz_get_ui($y);

        my $t = Math::GMPz::Rmpz_init();
        my $e = (Math::GMPz::Rmpz_sizeinbase($x, $y) || goto &_nan) - 1;

        if ($e > 0) {
            Math::GMPz::Rmpz_ui_pow_ui($t, $y, $e);
            Math::GMPz::Rmpz_cmp($t, $x) > 0 and --$e;
        }

        Math::GMPz::Rmpz_set_ui($t, $e);
        return $t;
    }

    my $e = 0;
    my $t = Math::GMPz::Rmpz_init();

    state $round_z = Math::MPFR::MPFR_RNDZ();

    state $logx = Math::MPFR::Rmpfr_init2_nobless(64);
    state $logy = Math::MPFR::Rmpfr_init2_nobless(64);

    Math::MPFR::Rmpfr_set_z($logx, $x, $round_z);
    Math::MPFR::Rmpfr_set_z($logy, $y, $round_z);

    Math::MPFR::Rmpfr_log($logx, $logx, $round_z);
    Math::MPFR::Rmpfr_log($logy, $logy, $round_z);

    Math::MPFR::Rmpfr_div($logx, $logx, $logy, $round_z);

    if (Math::MPFR::Rmpfr_fits_ulong_p($logx, $round_z)) {
        $e = Math::MPFR::Rmpfr_get_ui($logx, $round_z) - 1;
        Math::GMPz::Rmpz_pow_ui($t, $y, $e + 1);
    }
    else {
        Math::GMPz::Rmpz_set($t, $y);
    }

    for (; Math::GMPz::Rmpz_cmp($t, $x) <= 0 ; Math::GMPz::Rmpz_mul($t, $t, $y)) {
        ++$e;
    }

    Math::GMPz::Rmpz_set_ui($t, $e);
    $t;
}

1
