
use strict;
use warnings;

use Test::More tests => 5;

BEGIN { 
    use_ok('HTTP::Parser2::XS') 
};

{
    my $buf = "GET / HTTP/1.0\x0d\x0a".
              "Host: localhost\x0d\x0a".
              "Connection: keep-alive\x0d\x0a".
              "\x0d\x0a";
    my $r = {};
    my $rv = parse_http_request($buf, $r);

    ok $rv > 0, "rv > 0, complete request";
};

{
    my $buf = "GET / HTTP/1.0\x0d\x0a".
              "Host: local";
    my $r = {};
    my $rv = parse_http_request($buf, $r);

    ok $rv == -2, "rv == -2, incomplete request" or diag "rv = $rv";
};

{
    my $buf = "BOOMBOOMZCZXXZXCCZX\x0d\x0a".
              "\x0d\x0a";
    my $r = {};
    my $rv = parse_http_request($buf, $r);

    ok $rv == -1, "rv == -1, bad request" or diag "rv = $rv";
};

{
    my $buf = "GET / HTTP/1.0\x0d\x0a".
              "Host: localhost\x0d\x0a".
              "Connection".("x" x 1024).": keep-alive\x0d\x0a".
              "\x0d\x0a";    my $r = {};
    my $rv = parse_http_request($buf, $r);

    ok $rv == -1, "rv == -1, too long header" or diag "rv = $rv";
};


