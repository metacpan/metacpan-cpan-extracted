use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __dec__ => qw(Math::MPFR) => sub {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_sub_ui($r, $_[0], 1, $ROUND);
    $r;
};

Class::Multimethods::multimethod __dec__ => qw(Math::GMPq) => sub {
    state $mone = Math::GMPz::Rmpz_init_set_si_nobless(-1);
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_add_z($r, $_[0], $mone);
    $r;
};

Class::Multimethods::multimethod __dec__ => qw(Math::GMPz) => sub {
    my $r = Math::GMPz::Rmpz_init_set($_[0]);
    Math::GMPz::Rmpz_sub_ui($r, $r, 1);
    $r;
};

Class::Multimethods::multimethod __dec__ => qw(Math::MPC) => sub {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_sub_ui($r, $_[0], 1, $ROUND);
    $r;
};

1;
