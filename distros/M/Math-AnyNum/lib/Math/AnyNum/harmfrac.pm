use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __harmfrac__ {    # takes an unsigned integer
    my ($ui) = @_;

    $ui || goto &_zero;
    $ui < 0 && goto &_nan;

    # Use binary splitting for large values of n. (by Fredrik Johansson)
    # http://fredrik-j.blogspot.ro/2009/02/how-not-to-compute-harmonic-numbers.html
    if ($ui > 7000) {

        my $num = Math::GMPz::Rmpz_init_set_ui(1);
        my $den = Math::GMPz::Rmpz_init_set_ui($ui + 1);

        my $temp = Math::GMPz::Rmpz_init();

        # Translation of Dana Jacobsen's code from Math::Prime::Util::{PP,GMP}.
        #   https://metacpan.org/pod/Math::Prime::Util::PP
        #   https://metacpan.org/pod/Math::Prime::Util::GMP
        my $sub;
        $sub = sub {
            my ($num, $den) = @_;
            Math::GMPz::Rmpz_sub($temp, $den, $num);

            if (Math::GMPz::Rmpz_cmp_ui($temp, 1) == 0) {
                Math::GMPz::Rmpz_set($den, $num);
                Math::GMPz::Rmpz_set_ui($num, 1);
            }
            elsif (Math::GMPz::Rmpz_cmp_ui($temp, 2) == 0) {
                Math::GMPz::Rmpz_set($den, $num);
                Math::GMPz::Rmpz_mul_2exp($num, $num, 1);
                Math::GMPz::Rmpz_add_ui($num, $num, 1);
                Math::GMPz::Rmpz_addmul($den, $den, $den);
            }
            else {
                Math::GMPz::Rmpz_add($temp, $num, $den);
                Math::GMPz::Rmpz_tdiv_q_2exp($temp, $temp, 1);
                my $q = Math::GMPz::Rmpz_init_set($temp);
                my $r = Math::GMPz::Rmpz_init_set($temp);
                $sub->($num, $q);
                $sub->($r,   $den);
                Math::GMPz::Rmpz_mul($num,  $num, $den);
                Math::GMPz::Rmpz_mul($temp, $q,   $r);
                Math::GMPz::Rmpz_add($num, $num, $temp);
                Math::GMPz::Rmpz_mul($den, $den, $q);
            }
        };

        $sub->($num, $den);
        undef $sub;

        my $q = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_num($q, $num);
        Math::GMPq::Rmpq_set_den($q, $den);
        Math::GMPq::Rmpq_canonicalize($q);
        return $q;
    }

    my $num = Math::GMPz::Rmpz_init_set_ui(1);
    my $den = Math::GMPz::Rmpz_init_set_ui(1);

    for (my $k = 2 ; $k <= $ui ; ++$k) {
        Math::GMPz::Rmpz_mul_ui($num, $num, $k);    # num = num * k
        Math::GMPz::Rmpz_add($num, $num, $den);     # num = num + den
        Math::GMPz::Rmpz_mul_ui($den, $den, $k);    # den = den * k
    }

    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_num($r, $num);
    Math::GMPq::Rmpq_set_den($r, $den);
    Math::GMPq::Rmpq_canonicalize($r);
    $r;
}

1;
