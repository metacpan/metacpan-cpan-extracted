#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 23;

use Math::Primality qw/ is_strong_lucas_pseudoprime/;
use Math::GMPz;

ok(is_strong_lucas_pseudoprime(2), "is_strong_lucas_pseudoprime should return true for 2");
my $z = Math::GMPz->new(3);

### basic method handling ###
ok(is_strong_lucas_pseudoprime($z), "is_strong_lucas_pseudoprime should handle Math::GMPz objects");
ok(!is_strong_lucas_pseudoprime(9), 'is_strong_lucas_pseudoprime deals with perfect squares');
ok(!is_strong_lucas_pseudoprime(16), 'is_strong_lucas_pseudoprime deals with perfect squares');
ok(!is_strong_lucas_pseudoprime(100), 'is_strong_lucas_pseudoprime deals with perfect squares');
### test _check_two_and_even ###
ok (Math::Primality::_check_two_and_even(Math::GMPz->new(2)) == 1, '_check_two_and_even(2) should return 1');
ok (Math::Primality::_check_two_and_even(Math::GMPz->new(20)) == 0, '_check_two_and_even(20) should return 0');
ok (Math::Primality::_check_two_and_even(Math::GMPz->new(1)) == 0, '_check_two_and_even(1) should return 0');
### first five strong Lucas psuedoprimes ###
ok(is_strong_lucas_pseudoprime(5459), "is_strong_lucas_pseudoprime should return true for the first lucas pseudoprime"); 
ok(is_strong_lucas_pseudoprime(5777), "is_strong_lucas_pseudoprime should return true for the second lucas pseudoprime"); 
ok(is_strong_lucas_pseudoprime(10877), "is_strong_lucas_pseudoprime should return true for the third lucas pseudoprime"); 
ok(is_strong_lucas_pseudoprime(16109), "is_strong_lucas_pseudoprime should return true for the fourth lucas pseudoprime"); 
ok(is_strong_lucas_pseudoprime(18971), "is_strong_lucas_pseudoprime should return true for the fifth lucas pseudoprime"); 
### random non-prime numbers ###
ok(!is_strong_lucas_pseudoprime(5455), "is_strong_lucas_pseudoprime should not return true for a composite and non psuedoprime");
ok(!is_strong_lucas_pseudoprime(5781), "is_strong_lucas_pseudoprime should not return true for a composite and non psuedoprime");
### Test _find_dpq_selfridge ###
ok(
    eq_array( [Math::Primality::_find_dpq_selfridge(Math::GMPz->new(1993)) ], [ 5, 1, -1 ]),
    "_find_dpq_selfridge should return (5, 1, -1) for 1993"
);

ok(
    eq_array( [Math::Primality::_find_dpq_selfridge(Math::GMPz->new(1759)) ], [-11, 1, 3]),
    "_find_dpq_selfridge should return (-11, 1, 3) for 1759"
);

### Test _find_s_d ###
{
  my ($s, $d) = Math::Primality::_find_s_d(Math::GMPz->new(7));
  ok ($s == 1, "_find_s_d should return 7 = 3 * 2^1 + 1");
  is ("$d", "3",  "_find_s_d should return 7 = 3 * 2^1 + 1");  
}

{
  my ($s, $d) = Math::Primality::_find_s_d(Math::GMPz->new(17));
  ok ($s == 4, "_find_s_d should return 17 = 1 * 2^4 + 1");
  is ("$d", "1", "_find_s_d should return 17 = 1 * 2^4 + 1");
}

{
  my ($s, $d) = Math::Primality::_find_s_d(Math::GMPz->new(53525));
  ok ($s == 2, "_find_s_d should return 53525 = 13381 * 2^2 + 1");
  is ("$d", "13381", "_find_s_d should return 53525 = 13381 * 2^2 + 1");
}
