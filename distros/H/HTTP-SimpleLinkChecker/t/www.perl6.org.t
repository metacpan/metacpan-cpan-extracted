use Test::More 0.98;

use HTTP::SimpleLinkChecker;

subtest http => sub {
	try_it( 'https://www.perl6.org/' );
	};

subtest redirect => sub {
	# this will redirect to https, but Mojo should handle that for us
	try_it( 'http://www.perl6.org/' );
	};

done_testing();

sub try_it {
	my $code = HTTP::SimpleLinkChecker::check_link($_[0]);
	is( $code, 200, "I can talk to $_[0]!" );
	}
