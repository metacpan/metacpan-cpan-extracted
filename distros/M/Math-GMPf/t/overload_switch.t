# This file created in response to:
# https://github.com/sisyphus/math-decimal64/pull/1,
# which also applies to Math::GMPf
# Thanks to @hiratara

use strict;
use warnings;
use Math::GMPf;

use Test::More;

END { done_testing(); };

my $two = Math::GMPf->new(2);

cmp_ok($two - 7, '==', -5, "Math::GMPf object - IV");
cmp_ok(5 - $two, '==',  3, "IV - Math::GMPf object");

cmp_ok($two / 2, '==', 1, "Math::GMPf object / IV");
cmp_ok(8 / $two, '==', 4, "IV / Math::GMPf object");

cmp_ok($two ** 6, '==', 64, "Math::GMPf object ** IV");

eval { my $ret = 6 ** $two; };

like($@, qr/Cannot raise an integer to the power of a Math::GMPf object/,
      "IV ** Math::GMPf object");

cmp_ok($two, '>', 1, "Math::GMPf object > IV");
cmp_ok(4, '>', $two, "IV > Math::GMPf object");

cmp_ok($two, '>=', 1, "Math::GMPf object >= IV");
cmp_ok(4, '>=', $two, "IV >= Math::GMPf object");

cmp_ok($two, '<', 6,  "Math::GMPf object < IV");
cmp_ok(-4, '<', $two, "IV < Math::GMPf object");

cmp_ok($two, '<=', 6,  "Math::GMPf object <= IV");
cmp_ok(-4, '<=', $two, "IV <= Math::GMPf object");

cmp_ok($two <=> 6, '<', 0, "Math::GMPf object <=> IV");
cmp_ok(6 <=> $two, '>', 0, "IV <=> Math::GMPf object");

# These next 2 subs will cause failures here on perl-5.20.0
# and later if &PL_sv_yes or &PL_sv_no is encountered in the
# overload sub.

sub foo () {!0} # Breaks PL_sv_yes
sub bar () {!1} # Breaks PL_sv_no

# Cannot raise an integer to the power of a Math::GMPf object
