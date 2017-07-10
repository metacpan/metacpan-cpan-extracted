use 5.014;
use warnings;

sub __divmod__ {
    my ($x, $y) = @_;

    Math::GMPz::Rmpz_sgn($y)
      || return (_nan(), _nan());

    my $r = Math::GMPz::Rmpz_init();
    my $s = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_divmod($r, $s, $x, $y);
    ($r, $s);
}

1;
