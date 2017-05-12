BEGIN { print "1..4\n"; }

END { print "not ok\n" unless $loaded }

use Math::NoCarry;

$loaded = 1;

print "ok\n";

my @triads = (
	[qw(123 456 579)],
	[qw(890 135 925)],
	[qw(456 879 225)],
	);

eval {	
	foreach my $triad ( @triads )
		{
		my( $n, $m, $expected ) = @$triad;
		
		my $sum1 = Math::NoCarry::add( $n, $m );
		my $sum2 = Math::NoCarry::add( $m, $n );
		
		die "Different results for different orders!\n" .
			"[$n + $m] gave [$sum1]\n[$m + $n] gave [$sum2]\n"
			if $sum1 != $sum2;
		
		die "[$n + $m] gave [$sum1], but I expected [$expected]\n"
			unless $sum1 == $expected;
		}
	};
print STDERR $@ if $@;
print $@ ? 'not ' : '', "ok\n";
	
eval {	
	foreach my $triad ( @triads )
		{
		foreach my $n ( @$triad )
			{
			my $sum = Math::NoCarry::add( $n );
			
			die "[$n] gave [$sum], but I expected [$n]\n"
				unless $sum == $n;
			}
		}
	};
print STDERR $@ if $@;
print $@ ? 'not ' : '', "ok\n";

eval {	
	my $sum = Math::NoCarry::add();
			
	die "[NULL] gave [$sum], but I expected [FALSE]\n"
				if $sum;
	};
print STDERR $@ if $@;
print $@ ? 'not ' : '', "ok\n";

