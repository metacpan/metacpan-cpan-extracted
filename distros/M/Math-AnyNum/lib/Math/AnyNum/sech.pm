use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __sech__ => qw(Math::MPFR) => sub {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_sech($r, $_[0], $ROUND);
    $r;
};

# sech(x) = 1/cosh(x)
Class::Multimethods::multimethod __sech__ => qw(Math::MPC) => sub {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_cosh($r, $_[0], $ROUND);
    Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
    $r;
};

1;
