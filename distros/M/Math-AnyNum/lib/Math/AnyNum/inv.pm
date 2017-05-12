use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __inv__ => qw(Math::MPFR) => sub {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_ui_div($r, 1, $_[0], $ROUND);
    $r;
};

Class::Multimethods::multimethod __inv__ => qw(Math::GMPq) => sub {
    my ($x) = @_;

    # Check for division by zero
    Math::GMPq::Rmpq_sgn($x) || do {
        (@_) = _mpq2mpfr($x);
        goto &__inv__;
    };

    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_inv($r, $x);
    $r;
};

Class::Multimethods::multimethod __inv__ => qw(Math::GMPz) => sub {
    (@_) = _mpz2mpq($_[0]);
    goto &__inv__;
};

Class::Multimethods::multimethod __inv__ => qw(Math::MPC) => sub {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_ui_div($r, 1, $_[0], $ROUND);
    $r;
};

1;
