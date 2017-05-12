use 5.014;
use warnings;

our ($ROUND, $PREC);

sub __bernfrac__ {
    my ($n) = @_;    # $n is an unsigned integer

    if ($n == 0) {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_ui($r, 1, 1);
        return $r;
    }

    if (($n & 1) and ($n > 1)) {    # Bn = 0 for odd n>1
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_ui($r, 0, 1);
        return $r;
    }

    # Use a faster algorithm based on values of the Zeta function.
    # B(n) = (-1)^(n/2 + 1) * zeta(n)*2*n! / (2*pi)^n
    if ($n >= 50) {

        my $prec = (
            $n <= 156
            ? CORE::int($n * CORE::log($n) + 1)
            : CORE::int($n * CORE::log($n) / CORE::log(2) - 3 * $n)    # TODO: optimize for large n (>50_000)
        );

        my $f = Math::MPFR::Rmpfr_init2($prec);
        Math::MPFR::Rmpfr_zeta_ui($f, $n, $ROUND);                     # f = zeta(n)

        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_fac_ui($z, $n);                               # z = n!
        Math::GMPz::Rmpz_div_2exp($z, $z, $n - 1);                     # z = z / 2^(n-1)
        Math::MPFR::Rmpfr_mul_z($f, $f, $z, $ROUND);                   # f = f*z

        my $p = Math::MPFR::Rmpfr_init2($prec);
        Math::MPFR::Rmpfr_const_pi($p, $ROUND);                        # p = PI
        Math::MPFR::Rmpfr_pow_ui($p, $p, $n, $ROUND);                  # p = p^n
        Math::MPFR::Rmpfr_div($f, $f, $p, $ROUND);                     # f = f/p

        Math::GMPz::Rmpz_set_ui($z, 1);                                # z = 1
        Math::GMPz::Rmpz_mul_2exp($z, $z, $n + 1);                     # z = 2^(n+1)
        Math::GMPz::Rmpz_sub_ui($z, $z, 2);                            # z = z-2

        Math::MPFR::Rmpfr_mul_z($f, $f, $z, $ROUND);                   # f = f*z
        Math::MPFR::Rmpfr_round($f, $f);                               # f = [f]

        my $q = Math::GMPq::Rmpq_init();
        Math::MPFR::Rmpfr_get_q($q, $f);                               # q = f
        Math::GMPq::Rmpq_set_den($q, $z);                              # q = q/z
        Math::GMPq::Rmpq_canonicalize($q);                             # remove common factors

        Math::GMPq::Rmpq_neg($q, $q) if $n % 4 == 0;                   # q = -q    (iff 4|n)
        return $q;
    }

#<<<
    my @D = (
        Math::GMPz::Rmpz_init_set_ui(0),
        Math::GMPz::Rmpz_init_set_ui(1),
        map { Math::GMPz::Rmpz_init_set_ui(0) } (1 .. $n/2 - 1)
    );
#>>>

    my ($h, $w) = (1, 1);
    foreach my $i (0 .. $n - 1) {
        if ($w ^= 1) {
            Math::GMPz::Rmpz_add($D[$_], $D[$_], $D[$_ - 1]) for (1 .. $h - 1);
        }
        else {
            $w = $h++;
            Math::GMPz::Rmpz_add($D[$w], $D[$w], $D[$w + 1]) while --$w;
        }
    }

    my $den = Math::GMPz::Rmpz_init_set_ui(1);
    Math::GMPz::Rmpz_mul_2exp($den, $den, $n + 1);
    Math::GMPz::Rmpz_sub_ui($den, $den, 2);
    Math::GMPz::Rmpz_neg($den, $den) if $n % 4 == 0;

    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_num($r, $D[$h - 1]);
    Math::GMPq::Rmpq_set_den($r, $den);
    Math::GMPq::Rmpq_canonicalize($r);
    $r;
}

1;
