use 5.014;
use warnings;

# $x is a Math::GMPz object
# $y is a signed integer

sub __irootrem__ {
    my ($x, $y) = @_;

    if ($y == 0) {
        require Math::AnyNum::dec;
        Math::GMPz::Rmpz_sgn($x) || return (_zero(), _mone());    # 0^Inf = 0
        Math::GMPz::Rmpz_cmpabs_ui($x, 1) == 0 and return (_one(), __dec__($x));    # 1^Inf = 1 ; (-1)^Inf = 1
        return (_inf(), __dec__($x));
    }
    elsif ($y < 0) {
        my $sign = Math::GMPz::Rmpz_sgn($x) || return (_inf(), _zero());            # 1 / 0^k = Inf
        Math::GMPz::Rmpz_cmp_ui($x, 1) == 0 and return (_one(), _zero());           # 1 / 1^k = 1
        return ($sign < 0 ? (_nan(), _nan()) : (_zero(), _ninf()));
    }
    elsif ($y % 2 == 0 and Math::GMPz::Rmpz_sgn($x) < 0) {
        return (_nan(), _nan());
    }

    my $r = Math::GMPz::Rmpz_init();
    my $s = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_rootrem($r, $s, $x, $y);
    ($r, $s);
}

1;
