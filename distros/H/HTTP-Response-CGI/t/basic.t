use Test::More tests => 4;

BEGIN { use_ok('HTTP::Response::CGI') };

#  new_ok() does not work in Test::More version 0.62 (CentOS 5).
if (defined(&{'new_ok'})) {
	$logs = new_ok( 'HTTP::Response::CGI' );
} else {
	#  use the older new() + isa_ok().
	$logs = NatWeb::Logs->new();
	isa_ok($logs, 'HTTP::Response::CGI');
}

# Test sub-classing
isa_ok($logs, 'HTTP::Response');

# Test parse
can_ok($logs, 'parse');
