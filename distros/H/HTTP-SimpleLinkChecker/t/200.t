use Test::More 0.98;

use HTTP::SimpleLinkChecker;

subtest http => sub {
	try_it( 'http://blogs.perl.org/' );
	};

subtest https => sub {
	try_it( 'https://www.perl.org/' );
	};

done_testing();


sub try_it {
	my $code = HTTP::SimpleLinkChecker::check_link($_[0]);
	is( $code, 200, "I can talk to $_[0]!" );
	}
