#!perl -w

use strict;
$^W=1;

use lib 't/lib';

my ($seed, $cases, $iterations);
BEGIN {
	$seed = $ARGV[0] || 0;
	srand($seed);
	$cases = $ARGV[1] || 5;
	die unless $cases >= 1;
	$iterations = $ARGV[2] || 200;
	die unless $iterations >= 10;
}

use Test;

BEGIN {
	plan tests => $cases, todo => [];
}

BEGIN { $ENV{MATH_ROUND_FAIR_DEBUG} = 1 }
use Check_FairRound;
use Math::Round::Fair;

sub gen_test_case {
 	my $n = 5+int(rand(50));
	my $sqrtn = sqrt $n;
	my @in;
	for(1..$n) {
		my $x = rand(10000) - 3000;
		$x = int($x) unless rand($sqrtn)<1;
		$x += 2e-3 * rand() - 1e-3 if rand(2)<1;
		push @in, $x;
	}
	return @in;
}

my @cases;
for my $case (1..$cases) {
	# Generate all the cases first, so that the cases are the same even
	# if the runs use a different number of random numbers when the
	# implementation changes.
	my @in = gen_test_case;
	push @cases, \@in;
}
my $result = 0;
for my $case (1..$cases) {
	my $in = shift @cases;
	print "@$in\n" if 0;
	eval { Check_FairRound::run_case($in, $iterations, 1e-7/$cases) };
	if($@) {
		$result = 1 if @ARGV;
		chomp($@);
		ok(undef, 1, "$@ in case number $case (@$in) with seed=$seed");
	}
	else {
		ok(1);
	}
}
exit($result);

