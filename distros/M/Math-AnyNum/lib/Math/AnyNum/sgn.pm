use 5.014;
use warnings;

our ($PREC, $ROUND);

Class::Multimethods::multimethod __sgn__ => qw(Math::MPFR) => \&Math::MPFR::Rmpfr_sgn;
Class::Multimethods::multimethod __sgn__ => qw(Math::GMPq) => \&Math::GMPq::Rmpq_sgn;
Class::Multimethods::multimethod __sgn__ => qw(Math::GMPz) => \&Math::GMPz::Rmpz_sgn;

# sgn(x) = x / abs(x)
Class::Multimethods::multimethod __sgn__ => qw(Math::MPC) => sub {
    my ($x) = @_;
    my $abs = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPC::Rmpc_abs($abs, $x, $ROUND);

    if (Math::MPFR::Rmpfr_zero_p($abs)) {    # it's zero
        return 0;
    }

    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_div_fr($r, $x, $abs, $ROUND);
    $r;
};

1;
