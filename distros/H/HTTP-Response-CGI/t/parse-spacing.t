use Test::More tests => 10;

use HTTP::Response::CGI;

# Example test values.
my @headers = (
	'Content-type: text/html',
	'X-Forwarded-For: 127.0.0.1',
);
my $body = 'This is the body.';

my $output;
my $response;

# Test: regular newlines
$output = join( "\n", @headers ) . "\n\n" . $body;
$response = HTTP::Response::CGI->parse($output);
is( $response->protocol, undef , 'protocol is undefined when not given');
is( $response->code,     '200', 'status is the default (200)');
is( $response->message,  'OK', 'message is the default (OK)' );
is( $response->header('Content-type'), 'text/html', 'correctly parsed Content-type header');
is( $response->content, $body, 'correctly parsed content body');

# Test: newlines and carriage returns
$output = join( "\r\n", @headers ) . "\r\n\r\n" . $body;
$response = HTTP::Response::CGI->parse($output);
is( $response->protocol, undef , 'protocol is undefined when not given');
is( $response->code,     '200', 'status is the default (200)');
is( $response->message,  'OK', 'message is the default (OK)' );
is( $response->header('Content-type'), 'text/html', 'correctly parsed Content-type header');
is( $response->content, $body, 'correctly parsed content body');
