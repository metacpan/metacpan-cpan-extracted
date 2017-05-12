use strict;
use warnings;
use Test::More;

BEGIN {
	use lib qw[ ../lib lib/];
	use_ok('Math::LogRand', 0.05);
}

my $t=1;
my $min = 0;
my $max = 10;

for (1..1000){
	my $i = LogRand($min,$max);
	ok(
		($i <= $max and $i >= $min),
		"$i is between $min and $max"
	);
}

my $greater_than_81 = 0;
my $highest = 0;
$min = 20;
$max = 100;

for (1..1000000){
	my $i = LogRand($min,$max);
	$greater_than_81 ++ if $i > 81;
	$highest = $i if $i > $highest;
}

ok( $greater_than_81, "Got $greater_than_81 results greater than 81");

diag 'Highest was ', $highest;

my %occurs;
my $min = 20;
my $max = 100;
$occurs{ LogRand($min,$max) }++ for 0..1000;
# diag "$_\toccured $occurs{$_} times.\n" foreach sort keys %occurs;

foreach my $value (sort {$occurs{$a} <=> $occurs{$b} }
	keys %occurs)
{
	diag "$value occured $occurs{$value} times";
}

done_testing;

