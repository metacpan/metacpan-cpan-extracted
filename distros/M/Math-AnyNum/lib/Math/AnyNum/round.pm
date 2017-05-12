use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __round__ => qw(Math::MPFR $) => sub {
    my ($x, $prec) = @_;

    my $nth = -CORE::int($prec);

    my $p = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_set_str($p, '1e' . CORE::abs($nth), 10, $ROUND);

    my $r = Math::MPFR::Rmpfr_init2($PREC);

    if ($nth < 0) {
        Math::MPFR::Rmpfr_div($r, $x, $p, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_mul($r, $x, $p, $ROUND);
    }

    Math::MPFR::Rmpfr_round($r, $r);

    if ($nth < 0) {
        Math::MPFR::Rmpfr_mul($r, $r, $p, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_div($r, $r, $p, $ROUND);
    }

    $r;
};

Class::Multimethods::multimethod __round__ => qw(Math::MPC $) => sub {
    my ($x, $prec) = @_;

    my $real = Math::MPFR::Rmpfr_init2($PREC);
    my $imag = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPC::RMPC_RE($real, $x);
    Math::MPC::RMPC_IM($imag, $x);

    $real = __round__($real, $prec);
    $imag = __round__($imag, $prec);

    if (Math::MPFR::Rmpfr_zero_p($imag)) {
        return $real;
    }

    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_fr_fr($r, $real, $imag, $ROUND);
    $r;
};

Class::Multimethods::multimethod __round__ => qw(Math::GMPq $) => sub {
    my ($x, $prec) = @_;

    my $nth = -CORE::int($prec);

    my $n = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set($n, $x);

    my $sgn = Math::GMPq::Rmpq_sgn($n);

    if ($sgn < 0) {
        Math::GMPq::Rmpq_neg($n, $n);
    }

    my $p = Math::GMPz::Rmpz_init_set_str('1' . ('0' x CORE::abs($nth)), 10);

    if ($nth < 0) {
        Math::GMPq::Rmpq_div_z($n, $n, $p);
    }
    else {
        Math::GMPq::Rmpq_mul_z($n, $n, $p);
    }

    state $half = do {
        my $q = Math::GMPq::Rmpq_init_nobless();
        Math::GMPq::Rmpq_set_ui($q, 1, 2);
        $q;
    };

    Math::GMPq::Rmpq_add($n, $n, $half);

    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_set_q($z, $n);

    if (Math::GMPz::Rmpz_odd_p($z) and Math::GMPq::Rmpq_integer_p($n)) {
        Math::GMPz::Rmpz_sub_ui($z, $z, 1);
    }

    Math::GMPq::Rmpq_set_z($n, $z);

    if ($nth < 0) {
        Math::GMPq::Rmpq_mul_z($n, $n, $p);
    }
    else {
        Math::GMPq::Rmpq_div_z($n, $n, $p);
    }

    if ($sgn < 0) {
        Math::GMPq::Rmpq_neg($n, $n);
    }

    if (Math::GMPq::Rmpq_integer_p($n)) {
        Math::GMPz::Rmpz_set_q($z, $n);
        return $z;
    }

    $n;
};

Class::Multimethods::multimethod __round__ => qw(Math::GMPz $) => sub {
    (@_) = (_mpz2mpq($_[0]), $_[1]);
    goto &__round__;
};

1;
