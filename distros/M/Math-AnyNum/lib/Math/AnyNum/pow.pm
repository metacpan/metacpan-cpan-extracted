use 5.014;
use warnings;

our ($ROUND, $PREC);

#
## GMPq
#
Class::Multimethods::multimethod __pow__ => qw(Math::GMPq $) => sub {
    my ($x, $y) = @_;

    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_pow_ui($r, $x, CORE::abs($y));

    if ($y < 0) {
        Math::GMPq::Rmpq_sgn($r) || goto &Math::AnyNum::_inf;
        Math::GMPq::Rmpq_inv($r, $r);
    }

    $r;
};

Class::Multimethods::multimethod __pow__ => qw(Math::GMPq Math::GMPq) => sub {
    my ($x, $y) = @_;

    # Integer power
    if (Math::GMPq::Rmpq_integer_p($y)) {
        (@_) = ($x, Math::GMPq::Rmpq_get_d($y));
        goto &__pow__;
    }

    # (-x)^(a/b) is a complex number
    elsif (Math::GMPq::Rmpq_sgn($x) < 0) {
        (@_) = (_mpq2mpc($x), _mpq2mpc($y));
        goto &__pow__;
    }

    (@_) = (_mpq2mpfr($x), _mpq2mpfr($y));
    goto &__pow__;
};

Class::Multimethods::multimethod __pow__ => qw(Math::GMPq Math::GMPz) => sub {
    (@_) = ($_[0], Math::GMPz::Rmpz_get_d($_[1]));
    goto &__pow__;
};

Class::Multimethods::multimethod __pow__ => qw(Math::GMPq Math::MPFR) => sub {
    (@_) = (_mpq2mpfr($_[0]), $_[1]);
    goto &__pow__;
};

Class::Multimethods::multimethod __pow__ => qw(Math::GMPq Math::MPC) => sub {
    (@_) = (_mpq2mpc($_[0]), $_[1]);
    goto &__pow__;
};

#
## GMPz
#

Class::Multimethods::multimethod __pow__ => qw(Math::GMPz $) => sub {
    my ($x, $y) = @_;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_pow_ui($r, $x, CORE::abs($y));

    if ($y < 0) {
        Math::GMPz::Rmpz_sgn($r) || goto &Math::AnyNum::_inf;

        my $q = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_z($q, $r);
        Math::GMPq::Rmpq_inv($q, $q);
        return $q;
    }

    $r;
};

Class::Multimethods::multimethod __pow__ => qw(Math::GMPz Math::GMPz) => sub {
    (@_) = ($_[0], Math::GMPz::Rmpz_get_d($_[1]));
    goto &__pow__;
};

Class::Multimethods::multimethod __pow__ => qw(Math::GMPz Math::GMPq) => sub {
    if (Math::GMPq::Rmpq_integer_p($_[1])) {
        (@_) = ($_[0], Math::GMPq::Rmpq_get_d($_[1]));
    }
    else {
        (@_) = (_mpz2mpfr($_[0]), _mpq2mpfr($_[1]));
    }
    goto &__pow__;
};

Class::Multimethods::multimethod __pow__ => qw(Math::GMPz Math::MPFR) => sub {
    (@_) = (_mpz2mpfr($_[0]), $_[1]);
    goto &__pow__;
};

Class::Multimethods::multimethod __pow__ => qw(Math::GMPz Math::MPC) => sub {
    (@_) = (_mpz2mpc($_[0]), $_[1]);
    goto &__pow__;
};

#
## MPFR
#
Class::Multimethods::multimethod __pow__ => qw(Math::MPFR Math::MPFR) => sub {
    my ($x, $y) = @_;

    if (    Math::MPFR::Rmpfr_sgn($x) < 0
        and !Math::MPFR::Rmpfr_integer_p($y)
        and Math::MPFR::Rmpfr_number_p($y)) {
        (@_) = (_mpfr2mpc($x), $y);
        goto &__pow__;
    }

    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_pow($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __pow__ => qw(Math::MPFR $) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    $y < 0
      ? Math::MPFR::Rmpfr_pow_si($r, $x, $y, $ROUND)
      : Math::MPFR::Rmpfr_pow_ui($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __pow__ => qw(Math::MPFR Math::GMPq) => sub {
    (@_) = ($_[0], _mpq2mpfr($_[1]));
    goto &__pow__;
};

Class::Multimethods::multimethod __pow__ => qw(Math::MPFR Math::GMPz) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_pow_z($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __pow__ => qw(Math::MPFR Math::MPC) => sub {
    (@_) = (_mpfr2mpc($_[0]), $_[1]);
    goto &__pow__;
};

#
## MPC
#
Class::Multimethods::multimethod __pow__ => qw(Math::MPC Math::MPC) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_pow($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __pow__ => qw(Math::MPC $) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    $y < 0
      ? Math::MPC::Rmpc_pow_si($r, $x, $y, $ROUND)
      : Math::MPC::Rmpc_pow_ui($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __pow__ => qw(Math::MPC Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_pow_fr($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __pow__ => qw(Math::MPC Math::GMPz) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_pow_z($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __pow__ => qw(Math::MPC Math::GMPq) => sub {
    (@_) = ($_[0], _mpq2mpc($_[1]));
    goto &__pow__;
};

1;
