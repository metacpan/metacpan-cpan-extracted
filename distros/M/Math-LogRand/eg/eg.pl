	use Math::LogRand;
	my %test;
	my $min = 20;
	my $max = 100;
	$test{ LogRand($min,$max) }++ for 0..1000;
	print "$_\toccured $test{$_} times.\n" foreach sort keys %test;

