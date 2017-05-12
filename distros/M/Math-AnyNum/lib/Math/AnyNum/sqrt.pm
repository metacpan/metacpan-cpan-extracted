use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __sqrt__ => qw(Math::MPFR) => sub {
    my ($x) = @_;

    # Complex for x < 0
    if (Math::MPFR::Rmpfr_sgn($x) < 0) {
        (@_) = _mpfr2mpc($x);
        goto &__sqrt__;
    }

    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_sqrt($r, $x, $ROUND);
    $r;
};

Class::Multimethods::multimethod __sqrt__ => qw(Math::MPC) => sub {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_sqrt($r, $_[0], $ROUND);
    $r;
};

1;
