use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __inc__ => qw(Math::MPFR) => sub {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_add_ui($r, $_[0], 1, $ROUND);
    $r;
};

Class::Multimethods::multimethod __inc__ => qw(Math::GMPq) => sub {
    state $one = Math::GMPz::Rmpz_init_set_ui_nobless(1);
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_add_z($r, $_[0], $one);
    $r;
};

Class::Multimethods::multimethod __inc__ => qw(Math::GMPz) => sub {
    my $r = Math::GMPz::Rmpz_init_set($_[0]);
    Math::GMPz::Rmpz_add_ui($r, $r, 1);
    $r;
};

Class::Multimethods::multimethod __inc__ => qw(Math::MPC) => sub {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_add_ui($r, $_[0], 1, $ROUND);
    $r;
};

1;
