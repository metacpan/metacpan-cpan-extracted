use 5.014;
use warnings;

# $x is a Math::GMPz object
# $y is a signed integer

sub __iroot__ {
    my ($x, $y) = @_;

    if ($y == 0) {
        Math::GMPz::Rmpz_sgn($x) || return $x;    # 0^Inf = 0

        # 1^Inf = 1 ; (-1)^Inf = 1
        if (Math::GMPz::Rmpz_cmpabs_ui($x, 1) == 0) {
            return Math::GMPz::Rmpz_init_set_ui(1);
        }

        goto &_inf;
    }
    elsif ($y < 0) {
        my $sign = Math::GMPz::Rmpz_sgn($x)
          || goto &_inf;                          # 1 / 0^k = Inf

        if ($sign < 0) {
            goto &_nan;
        }

        if (Math::GMPz::Rmpz_cmp_ui($x, 1) == 0) {    # 1 / 1^k = 1
            return $x;
        }

        return Math::GMPz::Rmpz_init_set_ui(0);
    }
    elsif ($y % 2 == 0 and Math::GMPz::Rmpz_sgn($x) < 0) {
        goto &_nan;
    }

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_root($r, $x, $y);
    $r;
}

1;
