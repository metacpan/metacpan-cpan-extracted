# check core module: response

use strict;
use warnings;

use Test::More tests => 8;

#=== Dependencies
#none

#Response
use Konstrukt::Response;

my $r = Konstrukt::Response->new(
	status  => '200',
	message => 'OK',
	headers => {
		'Content-Type' => 'text/html'
	}
);

#header
is($r->header('Content-Type'), "text/html", "header: get");
is($r->header('cOntent_TypE'), "text/html", "header: get");
is($r->header('cOnteNT_TypE', "text/plain"), "text/plain", "header: set");
$r->header('content_type', "text/html");
is($r->header('Content-Type'), "text/html", "header: set");
is($r->header('Content-Length', 2342), 2342, "header: set");

#headers
is_deeply($r->headers(), { "Content-Length" => 2342, "Content-Type" => "text/html" }, "headers");

#status
is($r->status(), "200", "status: get");
is($r->status("404"), "404", "status: set");
