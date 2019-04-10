#!perl

use Test::More tests => 2;

use Math::ContinuedFraction;

#
# Albert H. Beiler example.
#
my $cf = Math::ContinuedFraction->from_root(23);
my $ta = $cf->to_ascii();

ok($ta eq q([4, [1, 3, 1, 8]]), "->to_ascii() check (returns '". $ta . "'");

$cf = Math::ContinuedFraction->from_root(13);
$ta = $cf->to_ascii();

ok($ta eq q([3, [1, 1, 1, 1, 6]]), "->to_ascii() check (returns '". $ta . "'");
exit(0);
