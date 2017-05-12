#!/usr/bin/env perl
use strict;
use warnings;
use HTTP::StreamParser::Request;

my $CRLF = "\x0d\x0a";
my $req_parser = HTTP::StreamParser::Request->new;
$req_parser->subscribe_to_event(
  http_method => sub { print "Method: $_[1]\n" },
  http_uri    => sub { print "URI:    $_[1]\n" },
  http_header => sub { print "Header: $_[1]: $_[2]\n" },
);
$req_parser->parse(join $CRLF, split /\n/, <<'EOF');
GET http://search.cpan.org/ HTTP/1.1
Host: search.cpan.org
Proxy-Connection: keep-alive
Cache-Control: max-age=0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.43 Safari/537.31
Accept-Encoding: gzip,deflate,sdch
Accept-Language: en-GB,en-US;q=0.8,en;q=0.6
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3
If-Modified-Since: Tue, 09 Apr 2013 00:40:15 GMT

EOF

