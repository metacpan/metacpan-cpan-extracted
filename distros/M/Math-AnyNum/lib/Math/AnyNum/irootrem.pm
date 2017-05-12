use 5.014;
use warnings;

# $x is a Math::GMPz object
# $y is a signed integer

sub __irootrem__ {
    my ($x, $y) = @_;

    if ($y == 0) {
        require Math::AnyNum::dec;
        Math::GMPz::Rmpz_sgn($x) || return (&Math::AnyNum::_zero(), &Math::AnyNum::_mone());    # 0^Inf = 0
        Math::GMPz::Rmpz_cmpabs_ui($x, 1) == 0 and return (&Math::AnyNum::_one(), __dec__($x)); # 1^Inf = 1 ; (-1)^Inf = 1
        return (&Math::AnyNum::_inf(), __dec__($x));
    }
    elsif ($y < 0) {
        my $sign = Math::GMPz::Rmpz_sgn($x) || return (&Math::AnyNum::_inf(), &Math::AnyNum::_zero());    # 1 / 0^k = Inf
        Math::GMPz::Rmpz_cmp_ui($x, 1) == 0 and return (&Math::AnyNum::_one(), &Math::AnyNum::_zero());   # 1 / 1^k = 1
        return ($sign < 0 ? (&Math::AnyNum::_nan(), &Math::AnyNum::_nan()) : (&Math::AnyNum::_zero(), &Math::AnyNum::_ninf()));
    }
    elsif ($y % 2 == 0 and Math::GMPz::Rmpz_sgn($x) < 0) {
        return (&Math::AnyNum::_nan(), &Math::AnyNum::_nan());
    }

    my $r = Math::GMPz::Rmpz_init();
    my $s = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_rootrem($r, $s, $x, $y);
    ($r, $s);
}

1;
