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
		my( $expected, $m, $n ) = @$triad;
		
		my $diff1 = Math::NoCarry::subtract( $n, $m );
		my $diff2 = Math::NoCarry::subtract( $n, $expected );
				
		die "[$n - $m] gave [$diff], but I expected [$expected]\n"
			unless $diff1 == $expected;
		die "[$n - $expected] gave [$diff], but I expected [$m]\n"
			unless $diff2 == $m;
		}
	};
print STDERR $@ if $@;
print $@ ? 'not ' : '', "ok\n";
	
eval {	
	foreach my $triad ( @triads )
		{
		foreach my $n ( @$triad )
			{
			my $diff = Math::NoCarry::subtract( $n );
			
			die "[$n] gave [$diff], but I expected [$n]\n"
				unless $diff == $n;
			}
		}
	};
print STDERR $@ if $@;
print $@ ? 'not ' : '', "ok\n";

eval {	
	my $diff = Math::NoCarry::subtract();
			
	die "[NULL] gave [$diff], but I expected [FALSE]\n"
				if $diff;
	};
print STDERR $@ if $@;
print $@ ? 'not ' : '', "ok\n";

