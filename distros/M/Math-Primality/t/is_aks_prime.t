#!/usr/bin/evn perl

use strict;
use warnings;
use Test::More tests => 232;
#use Carp::Always;

use Math::GMPz qw/:mpz/;
use POSIX qw(ceil floor); # for testing _Rmpz_logbase2* functions

BEGIN {
  use_ok ('Math::Primality::AKS' );
}
use Math::Primality::AKS qw/is_aks_prime/;

my $z = Math::GMPz->new(3);
ok( is_aks_prime($z), "is_aks_prime should handle Math::GMPz objects, three is prime" );
ok( is_aks_prime(2), '2 is prime');
ok(!is_aks_prime(1), '1 is not prime');
ok(!is_aks_prime(0), '0 is not prime');
ok(!is_aks_prime(-1), '-1 is not prime');

# What should it do for x < 0 ?
#ok(!is_aks_prime(-2), '-2 is not prime');
ok( !is_aks_prime(20), "20 is not prime");

# powers of 2 are never prime
for my $k (1..20) {
        Rmpz_ui_pow_ui($z, 2, ++$k );
        ok(!is_aks_prime($z), "2**$k=$z is not prime");
}

my @small_primes = qw/
5   7   11  13  17  19  23  29  31  37  41  43  47  53  59  61  67  71
73  79  83  89  97  101     103     107     109     113     127     131     137     139   149     151     157     163     167     173
2621    2633    2647    2657    2659    2663    2671    2677    2683    2687    2689    2693  2699    2707    2711    2713    2719    2729    2731    2741
2749    2753    2767    2777    2789    2791    2797    2801    2803    2819    2833    2837  2843    2851    2857    2861    2879    2887    2897    2903
2909    2917    2927    2939    2953    2957    2963    2969    2971    2999    3001    3011  3019    3023    3037    3041    3049    3061    3067    3079
3083    3089    3109    3119    3121    3137    3163    3167    3169    3181    3187    3191  3203    3209    3217    3221    3229    3251    3253    3257
3259    3271    3299    3301    3307    3313    3319    3323    3329    3331    3343    3347  3359    3361    3371    3373    3389    3391    3407    3413
3433    3449    3457    3461    3463    3467    3469    3491    3499    3511    3517    3527  3529    3533    3539    3541    3547    3557    3559    3571 
/;

map { ok(is_aks_prime($_), "$_ is an AKS prime") } @small_primes;

my @carmichael = qw/561 1105 1729 2465 2821 6601 8911
                    10585 15841 29341 41041 46657 52633
                    62745 63973 75361 101101
                    999838193331601
                    999840927672001
                    999851057445241
                    999878556600001
                    999885684921481
                    999895175363161
                    999902676805201
                    999907821232321
                    999919121100481
                    999922265173441
/;
map { ok(!is_aks_prime($_), "Carmichael Number $_ is not an AKS prime") } @carmichael;

# First 20 psp(2)'s
map { ok(!is_aks_prime($_), "Pseudoprime (base 2) $_ is not an AKS prime" ) } qw/
 341 561 645 1105 1387 1729 1905 2047
 2465 2701 2821 3277 4033 4369 4371
 4681 5461 6601 7957 8321
/;

