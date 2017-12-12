use 5.014;
use warnings;

our ($ROUND, $PREC);

# Implemented as:
#    beta(x,y) = gamma(x)*gamma(y) / gamma(x+y)

state $has_beta = Math::MPFR::MPFR_VERSION_MAJOR() >= 4;

sub __beta__ {
    my ($x, $y) = @_;

    if ($has_beta) {    # available since mpfr-4.0.0
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_beta($r, $x, $y, $ROUND);
        return $r;
    }

    my $t1 = Math::MPFR::Rmpfr_init2($PREC);    # gamma(x+y)
    my $t2 = Math::MPFR::Rmpfr_init2($PREC);    # gamma(y)

    my $r = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPFR::Rmpfr_add($t1, $x, $y, $ROUND);
    Math::MPFR::Rmpfr_gamma($t1, $t1, $ROUND);
    Math::MPFR::Rmpfr_gamma($r,  $x,  $ROUND);
    Math::MPFR::Rmpfr_gamma($t2, $y,  $ROUND);
    Math::MPFR::Rmpfr_mul($r, $r, $t2, $ROUND);
    Math::MPFR::Rmpfr_div($r, $r, $t1, $ROUND);

    $r;
}

1;
