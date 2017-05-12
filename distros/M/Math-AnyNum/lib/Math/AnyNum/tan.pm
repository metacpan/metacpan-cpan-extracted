use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __tan__ => qw(Math::MPFR) => sub {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_tan($r, $_[0], $ROUND);
    $r;
};

Class::Multimethods::multimethod __tan__ => qw(Math::MPC) => sub {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_tan($r, $_[0], $ROUND);
    $r;
};

1;
