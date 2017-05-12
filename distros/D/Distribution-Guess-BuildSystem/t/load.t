BEGIN {
	@classes = qw(Distribution::Guess::BuildSystem);
	}

use Test::More tests => scalar @classes;

foreach my $class ( @classes )
	{
	$result = use_ok( $class );
	print "Bail out! $class did not compile [$@]\n" unless $result;
	}
