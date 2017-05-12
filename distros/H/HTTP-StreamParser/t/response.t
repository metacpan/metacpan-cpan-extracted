use strict;
use warnings;
use HTTP::StreamParser::Response;
use Test::More tests => 20;

my $CRLF = "\x0d\x0a";
my @req;
my $body = '';
my %hdr = (
	'Date' => 'Sun, 17 Mar 2013 02:05:27 GMT',
	'Server' => 'Some/Server (Perl)',
	'Cache-Control' => 'max-age=86399',
	'Content-Length' => '15',
	'Content-Type' => 'text/plain',
	'Expires' => 'Mon, 18 Mar 2013 02:05:27 GMT',
	'Last-Modified' => 'Sun, 17 Mar 2013 02:05:27 GMT',
	'X-Cache' => 'MISS from localhost',
	'X-Cache-Lookup' => 'HIT from localhost:3128',
	'Via' => '1.0 localhost (squid/3.1.19)',
);
my $p = HTTP::StreamParser::Response->new;
$p->subscribe_to_event(
	http_method => sub {
		my $method = $_[1];
		is($method, 'GET', 'correct method');
		push @req, $method;
	},
	http_uri => sub {
		my $uri = $_[1];
		is($uri, '/', 'correct URI');
		push @req, $uri;
	},
	http_header => sub {
		my ($k, $v) = @_[1,2];
		ok(exists $hdr{$k}, 'have this header (' . $k . ')');
		is($v, $hdr{$k}, 'header matches');
		push @req, [ $k => $v ];
	},
	http_body_chunk => sub {
		my ($txt) = $_[1];
		$body .= $txt;
	},
);

$p->parse($_) for split /(.{5})/, join $CRLF, split /\n/, <<'EOF';
HTTP/1.1 200 OK
Date: Sun, 17 Mar 2013 02:05:27 GMT
Server: Some/Server (Perl)
Cache-Control: max-age=86399
Content-Length: 15
Content-Type: text/plain
Expires: Mon, 18 Mar 2013 02:05:27 GMT
Last-Modified: Sun, 17 Mar 2013 02:05:27 GMT
X-Cache: MISS from localhost
X-Cache-Lookup: HIT from localhost:3128
Via: 1.0 localhost (squid/3.1.19)

This is text...
EOF
done_testing();

