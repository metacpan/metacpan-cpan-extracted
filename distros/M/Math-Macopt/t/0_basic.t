# This test case examines the optimizing ability of the Macopt in the equation
# sum_i (x_i - i)^2

use strict;
use Test::More tests => 14;

BEGIN {
	use_ok("Math::Macopt");
}

&main();

sub main
{
	# Some settings
	my $N = 10;
	my $epsilon = 0.001;
	my $verbose = 0;

	# Initialize the Macopt 
	my $macopt = new Math::Macopt::Base($N, $verbose);

	# Setup the function and its gradient
 	my $func = sub {
		my $x = shift;

		my $size = $macopt->size();
 		my $sum = 0;
 		foreach my $i (0..$size-1) {
 			$sum += ($x->[$i]-$i)**2;
 		}
 		
		return $sum;
 	};
 	my $dfunc = sub {
 		my $x = shift;

		my $size = $macopt->size();
 		my $g = ();
 		foreach my $i (0..$size-1) {
 			$g->[$i] = 2*($x->[$i]-$i); 
 		}
 
 		return $g;
 	};

	# Staring random vector
	my $x = [ map { rand() } (1..$N) ]; # [(1)x($N)];

	# Check the setting
	is($N, $macopt->size(), "The size() function okay.");
	eval {
		$macopt->setFunc(\&$func);
		$macopt->setDfunc(\&$dfunc);
	};
	ok(!$@, "Calling setFunc()/setDfunc() without error.");
	eval {
		$macopt->maccheckgrad($x, $N, $epsilon, 0);
	};
	ok(!$@, "Calling maccheckgrad() without error.");
	
	# Optimization 
	$macopt->macoptII($x, $N);
	
	foreach my $i (0..$N-1) {
		ok(($x->[$i] - $i) < 0.01, "Error at position $i less than 0.01");
	}
}
