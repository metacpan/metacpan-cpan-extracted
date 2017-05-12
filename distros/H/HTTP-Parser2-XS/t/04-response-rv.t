
use strict;
use warnings;

use Test::More tests => 5;

BEGIN { 
    use_ok('HTTP::Parser2::XS') 
};

{
    my $buf = "HTTP/1.0 200 OK\x0d\x0a".
              "Connection: keep-alive\x0d\x0a".
              "\x0d\x0a";
    my $r = {};
    my $rv = parse_http_response($buf, $r);

    ok $rv > 0, "rv > 0, complete response";
};

{
    my $buf = "HTTP/1.0 200 OK\x0d\x0a".
              "Host: local";
    my $r = {};
    my $rv = parse_http_response($buf, $r);

    ok $rv == -2, "rv == -2, incomplete response" or diag "rv = $rv";
};

{
    my $buf = "BOOMBOOMZCZXXZXCCZX\x0d\x0a".
              "\x0d\x0a";
    my $r = {};
    my $rv = parse_http_response($buf, $r);

    ok $rv == -1, "rv == -1, bad response" or diag "rv = $rv";
};

{
    my $buf = "HTTP/1.0 200 OK\x0d\x0a".
              "Connection".("x" x 1024).": keep-alive\x0d\x0a".
              "\x0d\x0a";
    my $r = {};
    my $rv = parse_http_response($buf, $r);

    ok $rv == -1, "rv == -1, too long header" or diag "rv = $rv";
};


