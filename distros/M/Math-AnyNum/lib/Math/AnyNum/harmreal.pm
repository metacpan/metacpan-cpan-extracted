use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __harmreal__ {
    my ($x) = @_;    # $x is a Math::MPFR object

    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_add_ui($r, $x, 1, $ROUND);
    Math::MPFR::Rmpfr_digamma($r, $r, $ROUND);

    my $t = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_euler($t, $ROUND);
    Math::MPFR::Rmpfr_add($r, $r, $t, $ROUND);

    $r;
}

1;
