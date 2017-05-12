
use strict;
use warnings;

use Test::More tests => 6;

BEGIN { 
    use_ok('HTTP::Parser2::XS') 
};

{
    my $buf = "HTTP/1.0 200 OK\x0d\x0a".
              "Host: localhost\x0d\x0a".
              "Connection: keep-alive\x0d\x0a".
              "\x0d\x0a";
    my $r = {};
    parse_http_response($buf, $r);

    ok $r->{'_keepalive'} == 1, "keepalive (connection: keep-alive)";
};

{
    my $buf = "HTTP/1.0 200 OK\x0d\x0a".
              "Host: localhost\x0d\x0a".
              "Connection: Keep-Alive, asdf\x0d\x0a".
              "\x0d\x0a";
    my $r = {};
    parse_http_response($buf, $r);

    ok $r->{'_keepalive'} == 1, "keepalive (connection: Keep-Alive, asdf)";
};

{
    my $buf = "HTTP/1.1 200 OK\x0d\x0a".
              "Host: localhost\x0d\x0a".
              "\x0d\x0a";
    my $r = {};
    parse_http_response($buf, $r);

    ok $r->{'_keepalive'} == 1, "keepalive (HTTP/1.1)";
};



{
    my $buf = "HTTP/1.1 200 OK\x0d\x0a".
              "Host: localhost\x0d\x0a".
              "Connection: close, qwerrrr\x0d\x0a".
              "\x0d\x0a";
    my $r = {};
    parse_http_response($buf, $r);

    ok $r->{'_keepalive'} == 0, "keepalive (HTTP/1.1, connection: close)";
};

{
    my $buf = "HTTP/1.0 200 OK\x0d\x0a".
              "Host: localhost\x0d\x0a".
              "Connection: close, asfdasdf\x0d\x0a".
              "\x0d\x0a";
    my $r = {};
    parse_http_response($buf, $r);

    ok $r->{'_keepalive'} == 0, "keepalive (HTTP/1.0, connection: close)";
};


