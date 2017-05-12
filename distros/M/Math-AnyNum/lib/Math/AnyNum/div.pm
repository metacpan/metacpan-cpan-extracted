use 5.014;
use warnings;

our ($ROUND, $PREC);

#
## GMPq
#
Class::Multimethods::multimethod __div__ => qw(Math::GMPq Math::GMPq) => sub {
    my ($x, $y) = @_;

    # Check for division by zero
    Math::GMPq::Rmpq_sgn($y) || do {
        (@_) = (_mpq2mpfr($x), $y);
        goto &__div__;
    };

    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_div($r, $x, $y);
    $r;
};

Class::Multimethods::multimethod __div__ => qw(Math::GMPq Math::GMPz) => sub {
    my ($x, $y) = @_;

    # Check for division by zero
    Math::GMPz::Rmpz_sgn($y) || do {
        (@_) = (_mpq2mpfr($x), $y);
        goto &__div__;
    };

    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_div_z($r, $x, $y);
    $r;
};

Class::Multimethods::multimethod __div__ => qw(Math::GMPq Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_set_q($r, $x, $ROUND);
    Math::MPFR::Rmpfr_div($r, $r, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __div__ => qw(Math::GMPq Math::MPC) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_q($r, $x, $ROUND);
    Math::MPC::Rmpc_div($r, $r, $y, $ROUND);
    $r;
};

#
## GMPz
#
Class::Multimethods::multimethod __div__ => qw(Math::GMPz Math::GMPz) => sub {
    my ($x, $y) = @_;

    # Check for division by zero
    Math::GMPz::Rmpz_sgn($y) || do {
        (@_) = (_mpz2mpfr($x), $y);
        goto &__div__;
    };

    # Check for exact divisibility
    if (Math::GMPz::Rmpz_divisible_p($x, $y)) {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_divexact($r, $x, $y);
        return $r;
    }

    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_num($r, $x);
    Math::GMPq::Rmpq_set_den($r, $y);
    Math::GMPq::Rmpq_canonicalize($r);
    $r;
};

Class::Multimethods::multimethod __div__ => qw(Math::GMPz $) => sub {
    my ($x, $y) = @_;

    # Check for exact divisibility
    if (Math::GMPz::Rmpz_divisible_ui_p($x, CORE::abs($y))) {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_divexact_ui($r, $x, CORE::abs($y));
        Math::GMPz::Rmpz_neg($r, $r) if $y < 0;
        return $r;
    }

    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_ui($r, 1, CORE::abs($y));
    Math::GMPq::Rmpq_set_num($r, $x);
    Math::GMPq::Rmpq_neg($r, $r) if $y < 0;
    Math::GMPq::Rmpq_canonicalize($r);
    $r;
};

Class::Multimethods::multimethod __div__ => qw(Math::GMPz Math::GMPq) => sub {
    my ($x, $y) = @_;

    # Check for division by zero
    Math::GMPq::Rmpq_sgn($y) || do {
        (@_) = (_mpz2mpfr($x), $y);
        goto &__div__;
    };

    my $q = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_z_div($q, $x, $y);
    $q;
};

Class::Multimethods::multimethod __div__ => qw(Math::GMPz Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_set_z($r, $x, $ROUND);
    Math::MPFR::Rmpfr_div($r, $r, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __div__ => qw(Math::GMPz Math::MPC) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_z($r, $x, $ROUND);
    Math::MPC::Rmpc_div($r, $r, $y, $ROUND);
    $r;
};

#
## MPFR
#
Class::Multimethods::multimethod __div__ => qw(Math::MPFR Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_div($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __div__ => qw(Math::MPFR $) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    $y < 0
      ? Math::MPFR::Rmpfr_div_si($r, $x, $y, $ROUND)
      : Math::MPFR::Rmpfr_div_ui($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __div__ => qw(Math::MPFR Math::GMPq) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_div_q($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __div__ => qw(Math::MPFR Math::GMPz) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_div_z($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __div__ => qw(Math::MPFR Math::MPC) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_fr($r, $x, $ROUND);
    Math::MPC::Rmpc_div($r, $r, $y, $ROUND);
    $r;
};

#
## MPC
#
Class::Multimethods::multimethod __div__ => qw(Math::MPC Math::MPC) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_div($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __div__ => qw(Math::MPC $) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    if ($y < 0) {
        Math::MPC::Rmpc_div_ui($r, $x, -$y, $ROUND);
        Math::MPC::Rmpc_neg($r, $r, $ROUND);
    }
    else {
        Math::MPC::Rmpc_div_ui($r, $x, $y, $ROUND);
    }
    $r;
};

Class::Multimethods::multimethod __div__ => qw(Math::MPC Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_div_fr($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __div__ => qw(Math::MPC Math::GMPz) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_z($r, $y, $ROUND);
    Math::MPC::Rmpc_div($r, $x, $r, $ROUND);
    $r;
};

Class::Multimethods::multimethod __div__ => qw(Math::MPC Math::GMPq) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_q($r, $y, $ROUND);
    Math::MPC::Rmpc_div($r, $x, $r, $ROUND);
    $r;
};

1;
