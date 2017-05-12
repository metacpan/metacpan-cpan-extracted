use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __boolify__ => qw(Math::MPFR) => sub {
    !Math::MPFR::Rmpfr_zero_p($_[0]);
};

Class::Multimethods::multimethod __boolify__ => qw(Math::GMPq) => sub {
    !!Math::GMPq::Rmpq_sgn($_[0]);
};

Class::Multimethods::multimethod __boolify__ => qw(Math::GMPz) => sub {
    !!Math::GMPz::Rmpz_sgn($_[0]);
};

Class::Multimethods::multimethod __boolify__ => qw(Math::MPC) => sub {
    my ($x) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPC::RMPC_RE($r, $x);
    Math::MPFR::Rmpfr_zero_p($r) || return 1;
    Math::MPC::RMPC_IM($r, $x);
    !Math::MPFR::Rmpfr_zero_p($r);
};

1;
