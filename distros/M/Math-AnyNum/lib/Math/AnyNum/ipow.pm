use 5.014;
use warnings;

# $x is a Math::GMPz object
# $y is a signed integer

sub __ipow__ {
    my ($x, $y) = @_;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_pow_ui($r, $x, CORE::abs($y));

    if ($y < 0) {
        Math::GMPz::Rmpz_sgn($r) || goto &_inf;    # 0^(-y) = Inf
        state $ONE_Z = Math::GMPz::Rmpz_init_set_ui_nobless(1);
        Math::GMPz::Rmpz_tdiv_q($r, $ONE_Z, $r);
    }

    $r;
}

1;
