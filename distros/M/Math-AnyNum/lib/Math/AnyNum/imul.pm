use 5.014;
use warnings;

sub __imul__ {    # takes two Math::GMPz objects
    my ($x, $y) = @_;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mul($r, $x, $y);
    $r;
}

1;
