use Test::More;

my @classes = qw(Distribution::Guess::BuildSystem);
foreach my $class ( @classes ) {
	use_ok $class or BAIL_OUT( "Bail out! $class did not compile [$@]\n" );
	}

done_testing();
