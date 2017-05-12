BEGIN { print "1..4\n"; }

END { print "not ok\n" unless $loaded }

use Math::NoCarry;

$loaded = 1;

print "ok\n";

my @triads = (
	[qw( 123  456  43878)],
	[qw(-123 -456  43878)],
	[qw(-123  456 -43878)],
	[qw( 123 -456 -43878)],
	
	[qw(456 123 43878)],
	[qw(456 879 28974)],
	[qw(879 456 28974)],

	[qw(  890 135  83750)],
	[qw( 135  890  83750)],
	[qw(-135  890 -83750)],
	[qw( 135 -890 -83750)],
	[qw(-135 -890  83750)],

	[qw(500 321 50500)],
	[qw(321 500 50500)],
	);

eval {	
	foreach my $triad ( @triads )
		{
		my( $n, $m, $expected ) = @$triad;
		
		my $product = Math::NoCarry::multiply( $n, $m );
				
		die "[$n x $m] gave [$product], but I expected [$expected]\n"
			unless $product == $expected;
		}
	};
print STDERR $@ if $@;
print $@ ? 'not ' : '', "ok\n";

eval {	
	foreach my $triad ( @triads )
		{
		foreach my $n ( @$triad )
			{
			my $product = Math::NoCarry::multiply( $n );
			
			die "[$n] gave [$product], but I expected [$n]\n"
				unless $product == $n;
			}
		}
	};
print STDERR $@ if $@;
print $@ ? 'not ' : '', "ok\n";

eval {	
	my $product = Math::NoCarry::multiply();
			
	die "[NULL] gave [$product], but I expected [FALSE]\n"
				if $product;
	};
print STDERR $@ if $@;
print $@ ? 'not ' : '', "ok\n";

