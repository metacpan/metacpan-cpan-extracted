use Test::More tests => 3;

# Parse normal HTTP output
# (to ensure that we're not breaking the parent HTTP::Response functionality)

use HTTP::Response::CGI;

# Example test values.
my $status = 'HTTP/1.1 200 OK';
my @headers = (
	'Content-type: text/html',
	'X-Forwarded-For: 127.0.0.1',
);
my $body = 'This is the body.';

my $output;
my $response;

$output = $status . "\n" . join( "\n", @headers ) . "\n\n" . $body;
$response = HTTP::Response::CGI->parse($output);
is( $response->protocol, 'HTTP/1.1' );
is( $response->code,     '200' );
is( $response->message,  'OK' );

