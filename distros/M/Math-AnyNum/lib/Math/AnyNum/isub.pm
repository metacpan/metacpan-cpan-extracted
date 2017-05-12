use 5.014;
use warnings;

sub __isub__ {    # takes two Math::GMPz objects
    my ($x, $y) = @_;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_sub($r, $x, $y);
    $r;
}

1;
