use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __abs__ => qw(Math::MPFR) => sub {
    my ($x) = @_;
    Math::MPFR::Rmpfr_sgn($x) >= 0 and return $x;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_abs($r, $x, $ROUND);
    $r;
};

Class::Multimethods::multimethod __abs__ => qw(Math::GMPq) => sub {
    my ($x) = @_;
    Math::GMPq::Rmpq_sgn($x) >= 0 and return $x;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_abs($r, $x);
    $r;
};

Class::Multimethods::multimethod __abs__ => qw(Math::GMPz) => sub {
    my ($x) = @_;
    Math::GMPz::Rmpz_sgn($x) >= 0 and return $x;
    my $r = Math::GMPz::Rmpz_init_set($x);
    Math::GMPz::Rmpz_abs($r, $r);
    $r;
};

Class::Multimethods::multimethod __abs__ => qw(Math::MPC) => sub {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPC::Rmpc_abs($r, $_[0], $ROUND);
    $r;
};

1;
