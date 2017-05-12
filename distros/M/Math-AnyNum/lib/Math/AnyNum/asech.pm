use 5.014;
use warnings;

our ($ROUND, $PREC);

# asech(x) = acosh(1/x)
Class::Multimethods::multimethod __asech__ => qw(Math::MPFR) => sub {
    my ($x) = @_;

    # Return a complex number for x < 0 or x > 1
    if (   Math::MPFR::Rmpfr_cmp_ui($x, 1) > 0
        or Math::MPFR::Rmpfr_cmp_ui($x, 0) < 0) {
        (@_) = _mpfr2mpc($x);
        goto &__asech__;
    }

    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
    Math::MPFR::Rmpfr_acosh($r, $r, $ROUND);
    $r;
};

# asech(x) = acosh(1/x)
Class::Multimethods::multimethod __asech__ => qw(Math::MPC) => sub {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_ui_div($r, 1, $_[0], $ROUND);
    Math::MPC::Rmpc_acosh($r, $r, $ROUND);
    $r;
};

1;
