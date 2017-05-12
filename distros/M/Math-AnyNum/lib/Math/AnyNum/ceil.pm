use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __ceil__ => qw(Math::MPFR) => sub {
    my ($x) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_ceil($r, $x);
    $r;
};

Class::Multimethods::multimethod __ceil__ => qw(Math::GMPq) => sub {
    my ($x) = @_;
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_set_q($z, $x);
    Math::GMPq::Rmpq_integer_p($x) && return $z;
    Math::GMPz::Rmpz_add_ui($z, $z, 1) if Math::GMPq::Rmpq_sgn($x) > 0;
    $z;
};

Class::Multimethods::multimethod __ceil__ => qw(Math::MPC) => sub {
    my ($x) = @_;

    my $real = Math::MPFR::Rmpfr_init2($PREC);
    my $imag = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPC::RMPC_RE($real, $x);
    Math::MPC::RMPC_IM($imag, $x);

    Math::MPFR::Rmpfr_ceil($real, $real);
    Math::MPFR::Rmpfr_ceil($imag, $imag);

    if (Math::MPFR::Rmpfr_zero_p($imag)) {
        return $real;
    }

    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_fr_fr($r, $real, $imag, $ROUND);
    $r;
};

1;
