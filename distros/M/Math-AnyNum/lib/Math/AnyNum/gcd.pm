use 5.014;
use warnings;

sub __gcd__ {
    my ($x, $y) = @_;

    my $r = Math::GMPz::Rmpz_init();

    ref($y)
      ? Math::GMPz::Rmpz_gcd($r, $x, $y)
      : Math::GMPz::Rmpz_gcd_ui($r, $x, $y);

    $r;
}

1;
