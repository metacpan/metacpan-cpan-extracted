use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __atan2__ => qw(Math::MPFR Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_atan2($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __atan2__ => qw(Math::MPFR Math::MPC) => sub {
    (@_) = (_mpfr2mpc($_[0]), $_[1]);
    goto &__atan2__;
};

# atan2(x, y) = atan(x/y)
Class::Multimethods::multimethod __atan2__ => qw(Math::MPC Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_div_fr($r, $x, $y, $ROUND);
    Math::MPC::Rmpc_atan($r, $r, $ROUND);
    $r;
};

# atan2(x, y) = atan(x/y)
Class::Multimethods::multimethod __atan2__ => qw(Math::MPC Math::MPC) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_div($r, $x, $y, $ROUND);
    Math::MPC::Rmpc_atan($r, $r, $ROUND);
    $r;
};

1;
