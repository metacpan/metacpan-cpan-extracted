
use strict;
use warnings;

use Test::More tests => 9;

BEGIN { 
    use_ok('HTTP::Parser2::XS') 
};

{
    my $buf = "GET /a%20s HTTP/1.0\x0d\x0a".
              "Host: localhost\x0d\x0a".
              "Connection: keep-alive\x0d\x0a".
              "Content-Length: 16000000000\x0d\x0a".
              "\x0d\x0a";
    my $r = {};
    parse_http_request($buf, $r);

    ok exists $r->{'host'}, "host header exists";
    ok $r->{'host'}->[0] eq 'localhost', "correct host";
    ok $r->{'_uri'} eq '/a s', "correct _uri (url_decoded)";
    ok exists $r->{'content-length'}, "has content length header";
    ok $r->{'_content_length'}, "has _content_length";
    ok $r->{'_content_length'} == 16000000000, "_content_length == 16000000000" 
        or diag $r->{'_content_length'};
};

{
    my $buf = "HTTP/1.0 200 OK\x0d\x0a".
              "Host: localhost\x0d\x0a".
              "Content-Type: text/html\x0d\x0a".
              "\x0d\x0a".
              "asdf";
    my $r = {};
    parse_http_response($buf, $r);

    ok exists $r->{'content-type'}, "content-type header exists";
    ok $r->{'content-type'}->[0] eq 'text/html', "correct content-type";
};
