use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __numify__ => qw(Math::MPFR) => sub {
    Math::MPFR::Rmpfr_get_d($_[0], $ROUND);
};

Class::Multimethods::multimethod __numify__ => qw(Math::GMPq) => \&Math::GMPq::Rmpq_get_d;
Class::Multimethods::multimethod __numify__ => qw(Math::GMPz) => \&Math::GMPz::Rmpz_get_d;

Class::Multimethods::multimethod __numify__ => qw(Math::MPC) => sub {
    my ($x) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPC::RMPC_RE($r, $x);
    Math::MPFR::Rmpfr_get_d($r, $ROUND);
};

1;
