use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __csc__ => qw(Math::MPFR) => sub {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_csc($r, $_[0], $ROUND);
    $r;
};

# csc(x) = 1/sin(x)
Class::Multimethods::multimethod __csc__ => qw(Math::MPC) => sub {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_sin($r, $_[0], $ROUND);
    Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
    $r;
};

1;
