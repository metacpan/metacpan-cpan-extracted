use 5.014;
use warnings;

our ($ROUND, $PREC);

# acsch(x) = asinh(1/x)
Class::Multimethods::multimethod __acsch__ => qw(Math::MPFR) => sub {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_ui_div($r, 1, $_[0], $ROUND);
    Math::MPFR::Rmpfr_asinh($r, $r, $ROUND);
    $r;
};

# acsch(x) = asinh(1/x)
Class::Multimethods::multimethod __acsch__ => qw(Math::MPC) => sub {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_ui_div($r, 1, $_[0], $ROUND);
    Math::MPC::Rmpc_asinh($r, $r, $ROUND);
    $r;
};

1;
