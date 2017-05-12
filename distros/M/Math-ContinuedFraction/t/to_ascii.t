#!perl

use Test::Simple tests => 1;

use Math::ContinuedFraction;

my $cf = Math::ContinuedFraction->new([1, 1, 1, 1]);
my $ta = $cf->to_ascii();

ok($ta eq q([1, 1, 1, 1]), "->ascii() check (returns '". $ta . "'");

exit(0);
