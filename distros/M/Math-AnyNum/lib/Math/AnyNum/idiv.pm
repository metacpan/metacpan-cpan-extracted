use 5.014;
use warnings;

sub __idiv__ {    # takes two Math::GMPz objects
    my ($x, $y) = @_;

    # Detect division by zero
    Math::GMPz::Rmpz_sgn($y) || do {
        my $sign = Math::GMPz::Rmpz_sgn($x);

        if ($sign == 0) {    # 0/0
            goto &Math::AnyNum::_nan;
        }
        elsif ($sign > 0) {    # x/0 where: x > 0
            goto &Math::AnyNum::_inf;
        }
        else {                 # x/0 where: x < 0
            goto &Math::AnyNum::_ninf;
        }
    };

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_tdiv_q($r, $x, $y);
    $r;
}

1;
