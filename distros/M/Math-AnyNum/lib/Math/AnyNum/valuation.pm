use 5.014;
use warnings;

sub __valuation__ {    # takes two Math::GMPz objects
    my ($x, $y) = @_;
    Math::GMPz::Rmpz_sgn($y) || return (0, $x);
    Math::GMPz::Rmpz_cmpabs_ui($y, 1) || return (0, $x);
    my $r = Math::GMPz::Rmpz_init();
    my $v = Math::GMPz::Rmpz_remove($r, $x, $y);
    ($v, $r);
}

1;
