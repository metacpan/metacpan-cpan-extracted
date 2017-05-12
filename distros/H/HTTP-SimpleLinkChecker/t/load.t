BEGIN { @classes = qw(HTTP::SimpleLinkChecker) }

use Test::More tests => scalar @classes;
	
foreach my $class ( @classes )
	{
	print "Bail out!" unless use_ok( $class );
	}
