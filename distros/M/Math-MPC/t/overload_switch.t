# This file created in response to:
# https://github.com/sisyphus/math-decimal64/pull/1,
# which also applies to Math::MPC
# Thanks to @hiratara

# This file duplicates some things already
# tested by t/switched_overload_args.t

use strict;
use warnings;
use Math::MPC;

use Test::More;

END { done_testing(); };

my $two = Math::MPC->new(2);

cmp_ok($two - 7, '==', -5, "Math::MPC object - IV");
cmp_ok(5 - $two, '==',  3, "IV - Math::MPC object");

cmp_ok($two / 2, '==', 1, "Math::MPC object / IV");
cmp_ok(8 / $two, '==', 4, "IV / Math::MPC object");

cmp_ok($two ** 6, '==', 64, "Math::MPC object ** IV");
cmp_ok(6 ** $two, '==', 36, "IV ** Math::MPC object");

# These next 2 subs will cause failures here on perl-5.20.0
# and later if &PL_sv_yes or &PL_sv_no is encountered in the
# overload sub.

sub foo () {!0} # Breaks PL_sv_yes
sub bar () {!1} # Breaks PL_sv_no
