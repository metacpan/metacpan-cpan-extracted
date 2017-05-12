#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(:hireswallclock cmpthese);
use HTTP::StreamParser::Request;
use HTTP::StreamParser::Response;
use HTTP::Parser::XS qw(parse_http_request parse_http_response HEADERS_AS_HASHREF);
use HTTP::Parser;
use Data::Dumper;

my $CRLF = "\x0d\x0a";
my $req = join $CRLF, split /\n/, <<'EOF';
GET / HTTP/1.1
Host: localhost
Content-Length: 15
Accept-Encoding: *

This is text...
EOF
my $res = join $CRLF, split /\n/, <<'EOF';
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

cmpthese -5, {
	'HTTP::StreamParser::Request' => sub {
		my $p = HTTP::StreamParser::Request->new;
		$p->parse($req);
	},
	'HTTP::StreamParser::Response' => sub {
		my $p = HTTP::StreamParser::Response->new;
		$p->parse($res);
	},
	'HTTP::Parser request' => sub {
		my $parser = HTTP::Parser->new(request => 1);
		die "bad req" unless 0 == $parser->add($req);
	},
	'HTTP::Parser response' => sub {
		my $parser = HTTP::Parser->new(response => 1);
		die "bad req" unless 0 == $parser->add($res);
	},
	'HTTP::Parser::XS request' => sub {
		my %env;
		die "bad req: " . Dumper(\%env) unless parse_http_request($req, \%env) > 0;
	},
	'HTTP::Parser::XS response' => sub {
		 my ($ret, $minor_version, $status, $message, $headers) = parse_http_response($res, HEADERS_AS_HASHREF);
		 die "error" unless ($status == 200) && ($ret > 0);
		 # warn "($ret, $minor_version, $status, $message, $headers)";
	},
};

