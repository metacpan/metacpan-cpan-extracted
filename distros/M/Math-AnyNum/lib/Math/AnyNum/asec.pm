use 5.014;
use warnings;

our ($ROUND, $PREC);

# asec(x) = acos(1/x)
Class::Multimethods::multimethod __asec__ => qw(Math::MPFR) => sub {
    my ($x) = @_;

    # Return a complex number for x > -1 and x < 1
    if (    Math::MPFR::Rmpfr_cmp_ui($x, 1) < 0
        and Math::MPFR::Rmpfr_cmp_si($x, -1) > 0) {
        (@_) = _mpfr2mpc($x);
        goto &__asec__;
    }

    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
    Math::MPFR::Rmpfr_acos($r, $r, $ROUND);
    $r;
};

# asec(x) = acos(1/x)
Class::Multimethods::multimethod __asec__ => qw(Math::MPC) => sub {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_ui_div($r, 1, $_[0], $ROUND);
    Math::MPC::Rmpc_acos($r, $r, $ROUND);
    $r;
};

1;
