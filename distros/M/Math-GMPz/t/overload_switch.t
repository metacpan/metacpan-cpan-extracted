# This file created in response to:
# https://github.com/sisyphus/math-decimal64/pull/1,
# which also applies to Math::GMPz
# Thanks to @hiratara

use strict;
use warnings;
use Math::GMPz;

use Test::More;

END { done_testing(); };

my $two = Math::GMPz->new(2);

cmp_ok($two - 7, '==', -5, "Math::GMPz object - IV");
cmp_ok(5 - $two, '==',  3, "IV - Math::GMPz object");

cmp_ok($two / 2, '==', 1, "Math::GMPz object / IV");
cmp_ok(8 / $two, '==', 4, "IV / Math::GMPz object");

cmp_ok($two ** 6, '==', 64, "Math::GMPz object ** IV");
cmp_ok(6 ** $two, '==', 36, "IV ** Math::GMPz object");

cmp_ok($two, '>', 1, "Math::GMPz object > IV");
cmp_ok(4, '>', $two, "IV > Math::GMPz object");

cmp_ok($two, '>=', 1, "Math::GMPz object >= IV");
cmp_ok(4, '>=', $two, "IV >= Math::GMPz object");

cmp_ok($two, '<', 6,  "Math::GMPz object < IV");
cmp_ok(-4, '<', $two, "IV < Math::GMPz object");

cmp_ok($two, '<=', 6,  "Math::GMPz object <= IV");
cmp_ok(-4, '<=', $two, "IV <= Math::GMPz object");

cmp_ok($two <=> 6, '<', 0, "Math::GMPz object <=> IV");
cmp_ok(6 <=> $two, '>', 0, "IV <=> Math::GMPz object");

my $iv = 50000;
eval {my $res = $iv << Math::GMPz->new(5);};
like($@, qr/^The argument that specifies the number of bits to be/, "Right hand operand of '<<' can't be a Math::GMPz object");

eval {my $res = $iv >> Math::GMPz->new(5);};
like($@, qr/^The argument that specifies the number of bits to be/, "Right hand operand of '>>' can't be a Math::GMPz object");

eval {$iv <<= Math::GMPz->new(5);};
like($@, qr/^The argument that specifies the number of bits to be/, "Right hand operand of '<<=' can't be a Math::GMPz object");

eval {$iv >>= Math::GMPz->new(5);};
like($@, qr/^The argument that specifies the number of bits to be/, "Right hand operand of '>>=' can't be a Math::GMPz object");



# These next 2 subs will cause failures here on perl-5.20.0
# and later if &PL_sv_yes or &PL_sv_no is encountered in the
# overload sub.

sub foo () {!0} # Breaks PL_sv_yes
sub bar () {!1} # Breaks PL_sv_no
