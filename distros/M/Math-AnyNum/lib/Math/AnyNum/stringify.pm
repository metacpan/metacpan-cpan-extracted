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
    my $digits = CORE::int($PREC >> 2);
    my $str = Math::MPFR::Rmpfr_get_str($x, 10, $digits, $ROUND);

    if ($str =~ s/e(-?[0-9]+)\z//) {
        my $exp = $1;

        my $sgn = '';
        if (substr($str, 0, 1) eq '-') {
            $sgn = '-';
            substr($str, 0, 1, '');
        }

        my ($before, $after) = split(/\./, $str);

        if ($exp > 0) {
            if ($exp >= CORE::length($after)) {
                $after = '.' . $after . "e$exp";
            }
            else {
                substr($after, $exp, 0, '.');
            }
        }
        else {
            if (CORE::abs($exp) >= CORE::length($before)) {

                my $diff = CORE::abs($exp) - CORE::length($before);

                if ($diff <= $digits) {
                    $before = ('0' x (CORE::abs($exp) - CORE::length($before) + 1)) . $before;
                    substr($before, $exp, 0, '.');
                }
                else {
                    $before .= '.';
                    $after  .= "e$exp";
                }
            }
        }

        $str = $sgn . $before . $after;
    }

    if (index($str, 'e') == -1) {
        $str =~ s/0+\z//;
        $str =~ s/\.\z//;
    }

    (!$str or $str eq '-') ? '0' : $str;
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
