#!/usr/bin/env perl

use strict;
use warnings;
use Cwd;
use Test::Most tests => 8;
use Data::Validate::URI;

BEGIN { use_ok('Geo::Coder::Free::Display') }

# Simulate environment variables
local %ENV = (
	HTTP_REFERER  => 'http://example.com',
	REMOTE_ADDR   => '127.0.0.1',
	CONFIG_DIR    => undef,
	DOCUMENT_ROOT => '/var/www',
	HOME          => '/home/user',
	GATEWAY_INTERFACE => 'CGI/1.1',
	REQUEST_METHOD => 'GET',
	QUERY_STRING => 'foo=bar&baz=qux',
	SCRIPT_URI => 'http://localhost',
);

# Create an instance of the module
my $display = Geo::Coder::Free::Display->new(
	config => { root_dir => Cwd::getcwd() }
);

# Test object creation
isa_ok($display, 'Geo::Coder::Free::Display', 'Object creation');

# Test retrieving the template path
ok($display->get_template_path({ modulepath => 'Geo/Coder/Free/Display/index' }), 'Template path retrieval');

# Test setting cookies
$display->set_cookie({ test_cookie => 'cookie_value' });
is_deeply(
	$display->{_cookies},
	{ test_cookie => 'cookie_value' },
	'Set cookie successfully'
);

# Test generating HTTP headers
like($display->http(), qr/Content-Type: text\/html; charset=UTF-8/, 'HTTP headers generation');

like($display->html(), qr/<html/i, 'HTML generation');
like($display->as_string(), qr/html>/i, 'as_string');

# Simulate HTML generation (assuming template exists)
sub mock_template {
	return "<html><body>Test Page</body></html>";
}
{
	no warnings 'redefine';
	*Geo::Coder::Free::Display::html = \&mock_template;
}
like($display->as_string({}), qr/Test Page/, 'HTML generation overriding html()');
