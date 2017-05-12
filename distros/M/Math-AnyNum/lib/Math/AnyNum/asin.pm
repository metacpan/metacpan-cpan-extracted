use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __asin__ => qw(Math::MPFR) => sub {
    my ($x) = @_;

    # Return a complex number for x < -1 or x > 1
    if (   Math::MPFR::Rmpfr_cmp_ui($x, 1) > 0
        or Math::MPFR::Rmpfr_cmp_si($x, -1) < 0) {
        my $r = _mpfr2mpc($x);
        Math::MPC::Rmpc_asin($r, $r, $ROUND);
        return $r;
    }

    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_asin($r, $x, $ROUND);
    $r;
};

Class::Multimethods::multimethod __asin__ => qw(Math::MPC) => sub {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_asin($r, $_[0], $ROUND);
    $r;
};

1;
