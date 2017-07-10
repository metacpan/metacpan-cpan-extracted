use 5.014;
use warnings;

our ($ROUND, $PREC);

Class::Multimethods::multimethod __stringify__ => qw(Math::GMPz) => sub {
    Math::GMPz::Rmpz_get_str($_[0], 10);
};

Class::Multimethods::multimethod __stringify__ => qw(Math::GMPq) => sub {
    Math::GMPq::Rmpq_get_str($_[0], 10);
};

Class::Multimethods::multimethod __stringify__ => qw(Math::MPFR) => sub {
    my ($x) = @_;

    Math::MPFR::Rmpfr_number_p($x)
      || return (
                   Math::MPFR::Rmpfr_nan_p($x)   ? 'NaN'
                 : Math::MPFR::Rmpfr_sgn($x) < 0 ? '-Inf'
                 :                                 'Inf'
                );

    # log(10)/log(2) =~ 3.3219280948873623
    my $digits = $PREC >> 2;
    my ($mantissa, $exponent) = Math::MPFR::Rmpfr_deref2($x, 10, $digits, $ROUND);

    my $sgn = '';
    if (substr($mantissa, 0, 1) eq '-') {
        $sgn = substr($mantissa, 0, 1, '');
    }

    $mantissa =~ /[^0]/ or return '0';

    if (CORE::abs($exponent) < CORE::length($mantissa)) {

        if ($exponent > 0) {
            substr($mantissa, $exponent, 0, '.');
        }
        else {
            substr($mantissa, 0, 0, '0.' . ('0' x CORE::abs($exponent)));
        }

        $mantissa = reverse($mantissa);
        $mantissa =~ s/^0+//;
        $mantissa =~ s/^\.//;
        $mantissa = reverse($mantissa);

        return ($sgn . $mantissa);
    }

    substr($mantissa, 1, 0, '.');
    $sgn . $mantissa . 'e' . ($exponent - 1);
};

Class::Multimethods::multimethod __stringify__ => qw(Math::MPC) => sub {
    my ($x) = @_;

    my $fr = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPC::RMPC_RE($fr, $x);
    my $re = __stringify__($fr);

    Math::MPC::RMPC_IM($fr, $x);
    my $im = __stringify__($fr);

    if ($im eq '0' or $im eq '-0') {
        return $re;
    }

    my $sign = '+';

    if (substr($im, 0, 1) eq '-') {
        $sign = '-';
        substr($im, 0, 1, '');
    }

    $im = '' if $im eq '1';
    $re eq '0' ? $sign eq '+' ? "${im}i" : "$sign${im}i" : "$re$sign${im}i";
};

1;
