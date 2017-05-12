use 5.014;
use warnings;

our ($ROUND, $PREC);

#
## MPFR
#

Class::Multimethods::multimethod __log__ => qw(Math::MPFR) => sub {
    my ($x) = @_;

    # Complex for x < 0
    if (Math::MPFR::Rmpfr_sgn($x) < 0) {
        (@_) = _mpfr2mpc($x);
        goto &__log__;
    }

    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_log($r, $x, $ROUND);
    $r;
};

Class::Multimethods::multimethod __log2__ => qw(Math::MPFR) => sub {
    my ($x) = @_;

    # Complex for x < 0
    if (Math::MPFR::Rmpfr_sgn($x) < 0) {
        (@_) = _mpfr2mpc($x);
        goto &__log2__;
    }

    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_log2($r, $x, $ROUND);
    $r;
};

Class::Multimethods::multimethod __log10__ => qw(Math::MPFR) => sub {
    my ($x) = @_;

    # Complex for x < 0
    if (Math::MPFR::Rmpfr_sgn($x) < 0) {
        (@_) = _mpfr2mpc($x);
        goto &__log10__;
    }

    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_log10($r, $x, $ROUND);
    $r;
};

#
## MPC
#

Class::Multimethods::multimethod __log__ => qw(Math::MPC) => sub {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_log($r, $_[0], $ROUND);
    $r;
};

Class::Multimethods::multimethod __log2__ => qw(Math::MPC) => sub {
    my ($x) = @_;
    my $r   = Math::MPC::Rmpc_init2($PREC);
    my $ln2 = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_log2($ln2, $ROUND);
    Math::MPC::Rmpc_log($r, $x, $ROUND);
    Math::MPC::Rmpc_div_fr($r, $r, $ln2, $ROUND);
    $r;
};

Class::Multimethods::multimethod __log10__ => qw(Math::MPC) => sub {
    my ($x) = @_;

    state $MPC_VERSION = Math::MPC::MPC_VERSION();

    my $r = Math::MPC::Rmpc_init2($PREC);

    if ($MPC_VERSION >= 65536) {    # available only in mpc>=1.0.0
        Math::MPC::Rmpc_log10($r, $x, $ROUND);
    }
    else {
        my $ln10 = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_ui($ln10, 10, $ROUND);
        Math::MPFR::Rmpfr_log($ln10, $ln10, $ROUND);
        Math::MPC::Rmpc_log($r, $x, $ROUND);
        Math::MPC::Rmpc_div_fr($r, $r, $ln10, $ROUND);
    }

    $r;
};

1;
