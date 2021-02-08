use Test::More tests => 1;

use HTTP::SimpleLinkChecker;
HTTP::SimpleLinkChecker::user_agent->max_redirects(5);

my $code = HTTP::SimpleLinkChecker::check_link(
	'https://httpbin.org/status/403');

is( $code, 403, "Unauthorized code works" );
