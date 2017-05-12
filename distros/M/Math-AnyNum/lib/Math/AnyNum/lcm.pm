use 5.014;
use warnings;

sub __lcm__ {
    my ($x, $y) = @_;

    my $r = Math::GMPz::Rmpz_init();

    ref($y)
      ? Math::GMPz::Rmpz_lcm($r, $x, $y)
      : Math::GMPz::Rmpz_lcm_ui($r, $x, $y);

    $r;
}

1;
