use 5.014;
use warnings;

our ($ROUND, $PREC);

# Algorithm due to Kevin J. McGown (December 8, 2005).
# Described in his paper: "Computing Bernoulli Numbers Quickly".

sub __bernfrac__ {
    my ($n) = @_;    # $n is an unsigned integer

    # B(n) = (-1)^(n/2 + 1) * zeta(n)*2*n! / (2*pi)^n

    if ($n == 0) {
        goto &_one;
    }

    if ($n == 1) {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_ui($r, 1, 2);
        return $r;
    }

    if (($n & 1) and ($n > 1)) {    # Bn = 0 for odd n>1
        goto &_zero;
    }

    state $round = Math::MPFR::MPFR_RNDN();
    state $tau   = 6.28318530717958647692528676655900576839433879875;

    my $log2B = (CORE::log(4 * $tau * $n) / 2 + $n * (CORE::log($n / $tau) - 1)) / CORE::log(2);

    my $prec = CORE::int($n + $log2B) +
          ($n <= 90 ? (3, 3, 4, 4, 6, 6, 6, 6, 7, 7, 7, 8, 8, 9, 10, 12, 9, 7, 6, 0, 0, 0,
                       0, 0, 0, 0, 0, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4)[($n>>1)-1] : 0);

    state $d = Math::GMPz::Rmpz_init_nobless();
    Math::GMPz::Rmpz_fac_ui($d, $n);                      # d = n!

    my $K = Math::MPFR::Rmpfr_init2($prec);
    Math::MPFR::Rmpfr_const_pi($K, $round);               # K = pi
    Math::MPFR::Rmpfr_pow_si($K, $K, -$n, $round);        # K = K^(-n)
    Math::MPFR::Rmpfr_mul_z($K, $K, $d, $round);          # K = K*d
    Math::MPFR::Rmpfr_div_2ui($K, $K, $n - 1, $round);    # K = K / 2^(n-1)

    # `d` is the denominator of bernoulli(n)
    Math::GMPz::Rmpz_set_ui($d, 2);                       # d = 2

    my @primes = (2);

    { # Sieve the primes <= n+1
      # Sieve of Eratosthenes + Dana Jacobsen's optimizations
        my $N = $n + 1;

        my @composite;
        my $bound = CORE::int(CORE::sqrt($N));

        for (my $i = 3 ; $i <= $bound ; $i += 2) {
            if (!exists($composite[$i])) {
                for (my $j = $i * $i ; $j <= $N ; $j += 2 * $i) {
                    undef $composite[$j];
                }
            }
        }

        foreach my $k (1 .. ($N - 1) >> 1) {
            if (!exists($composite[2 * $k + 1])) {

                push(@primes, 2 * $k + 1);

                if ($n % (2 * $k) == 0) {    # d = d*p   iff (p-1)|n
                    Math::GMPz::Rmpz_mul_ui($d, $d, 2 * $k + 1);
                }
            }
        }
    }

    state $N = Math::MPFR::Rmpfr_init2_nobless(64);
    Math::MPFR::Rmpfr_mul_z($K, $K, $d, $round);         # K = K*d

    state $_V = Math::MPFR::MPFR_VERSION_MAJOR();

    if ($_V >= 4) {
        state $R = Math::MPFR::Rmpfr_init2_nobless(64);
        Math::MPFR::Rmpfr_set_ui($R, $n - 1, $round);        # R = 1
        Math::MPFR::Rmpfr_ui_div($R, 1, $R, $round);         # R = 1/R
        Math::MPFR::Rmpfr_pow($N, $K, $R, $round);           # N = K^R
    }
    else {
        Math::MPFR::Rmpfr_root($N, $K, $n - 1, $round);      # N = K^(1/(n-1))     (deprecated since mpfr-4.0.0)
    }

    Math::MPFR::Rmpfr_ceil($N, $N);                      # N = ceil(N)

    my $bound = Math::MPFR::Rmpfr_get_ui($N, $round);    # bound = int(N)

    my $z = Math::MPFR::Rmpfr_init2($prec);              # zeta(n)
    my $u = Math::GMPz::Rmpz_init();                     # p^n

    Math::MPFR::Rmpfr_set_ui($z, 1, $round);             # z = 1

    # `Math::GMPf` would perform slightly faster here.
    for (my $i = 0 ; $primes[$i] <= $bound ; ++$i) {     # primes <= bound
        Math::GMPz::Rmpz_ui_pow_ui($u, $primes[$i], $n);    # u = p^n
        Math::MPFR::Rmpfr_mul_z($z, $z, $u, $round);        # z = z*u
        Math::GMPz::Rmpz_sub_ui($u, $u, 1);                 # u = u-1
        Math::MPFR::Rmpfr_div_z($z, $z, $u, $round);        # z = z/u
    }

    Math::MPFR::Rmpfr_mul($z, $z, $K, $round);              # z = z * K
    Math::MPFR::Rmpfr_ceil($z, $z);                         # z = ceil(z)

    my $q = Math::GMPq::Rmpq_init();

    Math::GMPq::Rmpq_set_den($q, $d);                       # denominator
    Math::MPFR::Rmpfr_get_z($d, $z, $round);
    Math::GMPz::Rmpz_neg($d, $d) if $n % 4 == 0;            # d = -d, iff 4|n
    Math::GMPq::Rmpq_set_num($q, $d);                       # numerator

    return $q;                                              # Bn
}

1;
