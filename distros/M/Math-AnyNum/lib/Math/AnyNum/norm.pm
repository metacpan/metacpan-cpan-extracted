use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __norm__ => qw(Math::MPC) => sub {
    my ($x) = @_;
    my $f = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPC::Rmpc_norm($f, $x, $ROUND);
    $f;
};

Class::Multimethods::multimethod __norm__ => qw(Math::MPFR) => sub {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_sqr($r, $_[0], $ROUND);
    $r;
};

Class::Multimethods::multimethod __norm__ => qw(Math::GMPz) => sub {
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mul($r, $_[0], $_[0]);
    $r;
};

Class::Multimethods::multimethod __norm__ => qw(Math::GMPq) => sub {
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_mul($r, $_[0], $_[0]);
    $r;
};

1;
