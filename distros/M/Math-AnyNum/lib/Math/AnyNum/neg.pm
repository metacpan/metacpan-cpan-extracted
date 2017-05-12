use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __neg__ => qw(Math::MPFR) => sub {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_neg($r, $_[0], $ROUND);
    $r;
};

Class::Multimethods::multimethod __neg__ => qw(Math::GMPq) => sub {
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_neg($r, $_[0]);
    $r;
};

Class::Multimethods::multimethod __neg__ => qw(Math::GMPz) => sub {
    my $r = Math::GMPz::Rmpz_init_set($_[0]);
    Math::GMPz::Rmpz_neg($r, $r);
    $r;
};

Class::Multimethods::multimethod __neg__ => qw(Math::MPC) => sub {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_neg($r, $_[0], $ROUND);
    $r;
};

1;
