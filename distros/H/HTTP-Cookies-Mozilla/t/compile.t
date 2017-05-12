use Test::More tests => 1;
	
foreach my $class ( "HTTP::Cookies::Mozilla" )
	{
	print "bail out! $class did not compile" unless use_ok( $class );
	}

