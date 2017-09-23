use 5.014;
use warnings;

sub __irand__ {
    my ($x, $y, $state) = @_;

    if (defined($y)) {
        my $cmp = Math::GMPz::Rmpz_cmp($y, $x);

        if ($cmp == 0) {
            return $x;
        }
        elsif ($cmp < 0) {
            ($x, $y) = ($y, $x);
        }

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sub($r, $y, $x);
        Math::GMPz::Rmpz_add_ui($r, $r, 1);
        Math::GMPz::Rmpz_urandomm($r, $state, $r, 1);
        Math::GMPz::Rmpz_add($r, $r, $x);
        return $r;
    }

    my $sgn = Math::GMPz::Rmpz_sgn($x) || return $x;

    my $r = Math::GMPz::Rmpz_init_set($x);

    if ($sgn < 0) {
        Math::GMPz::Rmpz_sub_ui($r, $r, 1);
    }
    else {
        Math::GMPz::Rmpz_add_ui($r, $r, 1);
    }

    Math::GMPz::Rmpz_urandomm($r, $state, $r, 1);
    Math::GMPz::Rmpz_neg($r, $r) if $sgn < 0;
    return $r;
}

1;
