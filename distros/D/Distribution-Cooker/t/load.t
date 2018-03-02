use Test::More;

my @classes = qw(Distribution::Cooker);

foreach my $class ( @classes ) {
	BAIL_OUT( "Bail out! $class did not compile\n" )
		unless use_ok( $class );
	}

done_testing();
