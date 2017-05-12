use 5.014;
use warnings;

our ($ROUND, $PREC);

#
## MPFR
#
Class::Multimethods::multimethod __cmp__ => qw(Math::MPFR Math::MPFR) => sub {

    if (   Math::MPFR::Rmpfr_nan_p($_[0])
        or Math::MPFR::Rmpfr_nan_p($_[1])) {
        return undef;
    }

    Math::MPFR::Rmpfr_cmp($_[0], $_[1]);
};

Class::Multimethods::multimethod __cmp__ => qw(Math::MPFR Math::GMPz) => sub {
    Math::MPFR::Rmpfr_nan_p($_[0]) && return undef;
    Math::MPFR::Rmpfr_cmp_z($_[0], $_[1]);
};

Class::Multimethods::multimethod __cmp__ => qw(Math::MPFR Math::GMPq) => sub {
    Math::MPFR::Rmpfr_nan_p($_[0]) && return undef;
    Math::MPFR::Rmpfr_cmp_q($_[0], $_[1]);
};

Class::Multimethods::multimethod __cmp__ => qw(Math::MPFR Math::MPC) => sub {
    (@_) = (_mpfr2mpc($_[0]), $_[1]);
    goto &__cmp__;
};

Class::Multimethods::multimethod __cmp__ => qw(Math::MPFR $) => sub {
    my ($x, $y) = @_;
    Math::MPFR::Rmpfr_nan_p($x) && return undef;
    $y < 0
      ? Math::MPFR::Rmpfr_cmp_si($x, $y)
      : Math::MPFR::Rmpfr_cmp_ui($x, $y);
};

#
## GMPq
#
Class::Multimethods::multimethod __cmp__ => qw(Math::GMPq Math::GMPq) => sub {
    Math::GMPq::Rmpq_cmp($_[0], $_[1]);
};

Class::Multimethods::multimethod __cmp__ => qw(Math::GMPq Math::GMPz) => sub {
    Math::GMPq::Rmpq_cmp_z($_[0], $_[1]);
};

Class::Multimethods::multimethod __cmp__ => qw(Math::GMPq Math::MPFR) => sub {
    Math::MPFR::Rmpfr_nan_p($_[1]) && return undef;
    -(Math::MPFR::Rmpfr_cmp_q($_[1], $_[0]));
};

Class::Multimethods::multimethod __cmp__ => qw(Math::GMPq Math::MPC) => sub {
    (@_) = (_mpq2mpc($_[0]), $_[1]);
    goto &__cmp__;
};

Class::Multimethods::multimethod __cmp__ => qw(Math::GMPq $) => sub {
    my ($x, $y) = @_;
    $y < 0
      ? Math::GMPq::Rmpq_cmp_si($x, $y, 1)
      : Math::GMPq::Rmpq_cmp_ui($x, $y, 1);
};

#
## GMPz
#
Class::Multimethods::multimethod __cmp__ => qw(Math::GMPz Math::GMPz) => sub {
    Math::GMPz::Rmpz_cmp($_[0], $_[1]);
};

Class::Multimethods::multimethod __cmp__ => qw(Math::GMPz Math::GMPq) => sub {
    -(Math::GMPq::Rmpq_cmp_z($_[1], $_[0]));
};

Class::Multimethods::multimethod __cmp__ => qw(Math::GMPz Math::MPFR) => sub {
    Math::MPFR::Rmpfr_nan_p($_[1]) && return undef;
    -(Math::MPFR::Rmpfr_cmp_z($_[1], $_[0]));
};

Class::Multimethods::multimethod __cmp__ => qw(Math::GMPz Math::MPC) => sub {
    (@_) = (_mpz2mpc($_[0]), $_[1]);
    goto &__cmp__;
};

Class::Multimethods::multimethod __cmp__ => qw(Math::GMPz $) => sub {
    my ($x, $y) = @_;
    $y < 0
      ? Math::GMPz::Rmpz_cmp_si($x, $y)
      : Math::GMPz::Rmpz_cmp_ui($x, $y);
};

#
## MPC
#
Class::Multimethods::multimethod __cmp__ => qw(Math::MPC Math::MPC) => sub {
    my ($x, $y) = @_;

    my $f = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPC::RMPC_RE($f, $x);
    Math::MPFR::Rmpfr_nan_p($f) && return undef;

    Math::MPC::RMPC_RE($f, $y);
    Math::MPFR::Rmpfr_nan_p($f) && return undef;

    Math::MPC::RMPC_IM($f, $x);
    Math::MPFR::Rmpfr_nan_p($f) && return undef;

    Math::MPC::RMPC_IM($f, $y);
    Math::MPFR::Rmpfr_nan_p($f) && return undef;

    my $si = Math::MPC::Rmpc_cmp($x, $y);
    my $re_cmp = Math::MPC::RMPC_INEX_RE($si);
    $re_cmp == 0 or return $re_cmp;
    Math::MPC::RMPC_INEX_IM($si);
};

Class::Multimethods::multimethod __cmp__ => qw(Math::MPC Math::GMPz) => sub {
    (@_) = ($_[0], _mpz2mpc($_[1]));
    goto &__cmp__;
};

Class::Multimethods::multimethod __cmp__ => qw(Math::MPC Math::GMPq) => sub {
    (@_) = ($_[0], _mpq2mpc($_[1]));
    goto &__cmp__;
};

Class::Multimethods::multimethod __cmp__ => qw(Math::MPC Math::MPFR) => sub {
    (@_) = ($_[0], _mpfr2mpc($_[1]));
    goto &__cmp__;
};

Class::Multimethods::multimethod __cmp__ => qw(Math::MPC $) => sub {
    (@_) = ($_[0], _any2mpc(_str2obj($_[1])));
    goto &__cmp__;
};

1;
