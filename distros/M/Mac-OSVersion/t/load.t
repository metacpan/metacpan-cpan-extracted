use Test::More;

my @classes = qw(Mac::OSVersion);
foreach my $class ( @classes ) {
	print "Bail out! $class did not compile\n" unless use_ok( $class );
	}

done_testing();
