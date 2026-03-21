# Test 4 unexported but documented functions, added in Math-MPFR-4.47:
# 1. Math::MPFR::_strlen - returns the length of the (string) argument as assessed by C's strlen().
# 2. Math::MPFR::_SvCUR - returns the value of the string  argument's CUR (in bytes).
# 3. Math::MPFR::_SvCUR_set - sets the CUR of the 1st (string) arg to the no. of bytes specified by the 2nd arg.
# 4. Math::MPFR::_SvLEN - returns the size of the string buffer (in bytes) in the SV.
# These 3 functions don't act on Math::MPFR objects, but they may be of use in doctoring strings that have
# been allocated by perl, then passed to a Math::MPFR XSub to be assigned some value.

use strict;
use warnings;
use Math::MPFR qw(:mpfr);

use Test::More;

*c_len      = \&Math::MPFR::_strlen;
*sv_cur     = \&Math::MPFR::_SvCUR;
*sv_cur_set = \&Math::MPFR::_SvCUR_set;
*sv_len     = \&Math::MPFR::_SvLEN;

my $buf = 'abc' . chr(0) . ('z' x 20);

my $size = sv_len($buf);
cmp_ok($size, '>', 24, "SvLEN is as expected");
cmp_ok(sv_cur($buf), '==', 24, "SvCUR is as expected");
cmp_ok(c_len($buf), '==', 3, "C strlen is as expected");
cmp_ok(length($buf), '==', 24, "Perl length (24) is as expected");

# Change CUR to 3:
sv_cur_set($buf, 3);
cmp_ok(sv_cur($buf), '==', 3, "CUR successfully altered");
cmp_ok(length($buf), '==', 3, "Perl length is now 3 as expected");
cmp_ok(sv_len($buf), '==', $size, "SvLEN is unchanged as expected");

Rmpfr_sprintf($buf, "%Ra", sqrt(Math::MPFR->new(2)), $size);
cmp_ok($buf, 'eq', '0x1.6a09e667f3bcdp+0', "buffer set to sqrt 2");

my $cur_size = sv_cur($buf);
sv_cur_set($buf, $cur_size - 2);

cmp_ok(sv_cur($buf), '==', $cur_size - 2, "SvCUR reduced by 2");

done_testing()
