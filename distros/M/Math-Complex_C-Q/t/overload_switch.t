# This file created in response to:
# https://github.com/sisyphus/math-decimal64/pull/1,
# which also applies to Math::Complex_C::Q
# Thanks to @hiratara

use strict;
use warnings;
use Math::Complex_C::Q qw(:all);

use Test::More;

END { done_testing(); };

my $mingw_w64_pow_bug = 0;
$mingw_w64_pow_bug = 1 if Math::Complex_C::Q::_mingw_w64_bug();

my $two = Math::Complex_C::Q->new(2);

cmp_ok($two - 7, '==', -5, "Math::Complex_C::Q object - IV");
cmp_ok(5 - $two, '==',  3, "IV - Math::Complex_C::Q object");

cmp_ok($two / 2, '==', 1, "Math::Complex_C object::Q / IV");
cmp_ok(8 / $two, '==', 4, "IV / Math::Complex_C object::Q");

unless($mingw_w64_pow_bug) {
  cmp_ok(real_cq($two ** 6), '>=', _min(64), "1: Math::Complex_C::Q ** IV");
  cmp_ok(real_cq($two ** 6), '<=', _max(64), "2: Math::Complex_C::Q ** IV");
  cmp_ok(real_cq(6 ** $two), '>=', _min(36), "1: IV ** Math::Complex_C::Q object");
  cmp_ok(real_cq(6 ** $two), '<=', _max(36), "2: IV ** Math::Complex_C::Q object");
}

# These next 2 subs will cause failures here on perl-5.20.0
# and later if &PL_sv_yes or &PL_sv_no is encountered in the
# overload sub.

sub foo () {!0} # Breaks PL_sv_yes
sub bar () {!1} # Breaks PL_sv_no

sub _min { return $_[0] - 1e-20 }
sub _max { return $_[0] + 1e-20 }
