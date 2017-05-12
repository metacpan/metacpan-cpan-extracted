#!perl -w

use strict;
$^W=1;
BEGIN { chdir "t" if -d "t"; }
use lib '../blib/arch', '../blib/lib';

use Test;
BEGIN { plan tests => 6, todo => [] }

use Math::Business::BlackScholes qw/historical_volatility/;

my $tol=2e-5; # Tolerance for floating point comparisons

sub ae {
	my $lhs=shift;
	my $rhs=shift;
	my $ref=shift || 0.0;
# print("$lhs =? $rhs\n");
	return abs($lhs-$rhs) <= (abs($rhs) + abs($ref))*$tol;
}

my $last=2;
my $ratio=exp(2.0/sqrt(250.0));
my @ary=($last);
for(1..10) {
	$last*=$ratio;
	push(@ary, $last, $last);
}

ok(ae(historical_volatility(\@ary), sqrt(20/19)));

# These are the closing prices of BRCM starting with 10/24/02, and going back
# one trading day per element:
my @closing_prices = (
  11.86, 11.76, 11.51, 11.05, 10.63, 12.45, 11.50, 13.60, 11.66, 11.47,
  11.01, 10.21, 9.80, 9.70, 10.10, 10.18, 11.51, 11.22, 10.68, 10.95,
  11.86,
);

ok(ae(Math::Business::BlackScholes::historical_volatility(
  \@closing_prices, 251
), 1.27506409));

ok(!defined Math::Business::BlackScholes::implied_volatility_call(
  90, 91, 100, 1, 0
));
my ($x)=Math::Business::BlackScholes::implied_volatility_call(
  90, 89, 100, 1, 0
);
ok(defined $x);

($x)=Math::Business::BlackScholes::implied_volatility_put(
  100, 91, 90, 1, 0
);
ok(!defined $x);
ok(defined Math::Business::BlackScholes::implied_volatility_put(
  100, 89, 90, 1, 0
));

