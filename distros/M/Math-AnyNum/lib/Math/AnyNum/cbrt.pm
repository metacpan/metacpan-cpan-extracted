use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __cbrt__ => qw(Math::MPFR) => sub {
    my ($x) = @_;

    # Complex for x < 0
    if (Math::MPFR::Rmpfr_sgn($x) < 0) {
        (@_) = _mpfr2mpc($_[0]);
        goto &__cbrt__;
    }

    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_cbrt($r, $x, $ROUND);
    $r;
};

Class::Multimethods::multimethod __cbrt__ => qw(Math::MPC) => sub {

    state $three_inv = do {
        my $r = Math::MPC::Rmpc_init2_nobless($PREC);
        Math::MPC::Rmpc_set_ui($r, 3, $ROUND);
        Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
        $r;
    };

    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_pow($r, $_[0], $three_inv, $ROUND);
    $r;
};

1;
