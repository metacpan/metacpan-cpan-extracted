#!/usr/bin/env perl
use strict;
use warnings;
use HTTP::StreamParser::Response;

my $CRLF = "\x0d\x0a";
my $resp_parser = HTTP::StreamParser::Response->new;
$resp_parser->subscribe_to_event(
   http_code   => sub { print "Code:   $_[1]\n" },
   http_status => sub { print "Status: $_[1]\n" },
   http_header => sub { print "Header: $_[1]: $_[2]\n" },
);
$resp_parser->parse(join $CRLF, split /\n/, <<'EOF');
HTTP/1.0 200 OK
Date: Sat, 13 Apr 2013 00:49:56 GMT
Server: Plack/Starman (Perl)
Cache-Control: max-age=3599
Content-Length: 10
Content-Type: text/plain
Expires: Sat, 13 Apr 2013 01:49:56 GMT
Last-Modified: Sat, 13 Apr 2013 00:49:56 GMT
Connection: keep-alive

Data here.
EOF

