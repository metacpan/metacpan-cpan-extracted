# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test::More qw(
	no_plan
	);

use Math::Round::Var;
ok(1); # If we made it this far, we're ok.

#########################
# XXX check for Math::Round and skips?
# XXX are we testing the parsing of inputs or what?

my $r = Math::Round::Var->new(0.0);
ok(ref($r) eq "Math::Round::Var::Float", "%0.0f");
ok($r->round(7.5) == 8);
$r = Math::Round::Var->new(0.001);
ok(ref($r) eq "Math::Round::Var::Float", "%0.3f");
ok($r->round(1.4443) == 1.444);
TODO: {
	my $n = $r->round(1.4445);
	local $TODO = "warts in sprintf" if $n == 1.444;
	ok($n == 1.445, "wart:  1.4445 should round to 1.445");
}
$r = Math::Round::Var->new(1/100);
ok(ref($r) eq "Math::Round::Var::Float", "1/100");
$r = Math::Round::Var->new(0.125);
ok(ref($r) eq "Math::Round::Var::Fraction", "1/8");
ok($r->round(0.175) == 0.125);
