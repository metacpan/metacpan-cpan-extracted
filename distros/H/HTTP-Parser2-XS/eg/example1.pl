#!/usr/bin/perl

use strict;
use warnings;

use HTTP::Parser2::XS;

{
    my $buf = "GET /a%20s?foo=bar HTTP/1.0\x0d\x0a".
              "Host: localhost\x0d\x0a".
              "Connection: keep-alive\x0d\x0a".
              "\x0d\x0a";

    my $r = {};
    my $rv = parse_http_request($buf, $r);

    if ($rv == -1) {
        # bad request or internal error
    } elsif ($rv == -2) {
        # incomplete request, call again when there is more data
        # in the buffer
    } else {
        # $rv contains the length of the request header on success

        print << "        END";

        rv           = $rv

        method       = "$r->{'_method'}"
        request_uri  = "$r->{'_request_uri'}"
        uri          = "$r->{'_uri'}"
        query_string = "$r->{'_query_string'}"
        protocol     = "$r->{'_protocol'}"

        keepalive    = $r->{'_keepalive'}
        
        END
    }

};

{
    my $buf = "HTTP/1.0 200 OK\x0d\x0a".
              "Host: localhost\x0d\x0a".
              "Content-Type: text/html\x0d\x0a".
              "\x0d\x0a".
              "asdf";

    my $r = {};
    my $rv = parse_http_response($buf, $r);

    if ($rv == -1) {
        # bad response or internal error
    } elsif ($rv == -2) {
        # incomplete response, call again when there is more data
        # in the buffer
    } else {
        # $rv contains the length of the request header on success

        print << "        END";

        rv           = $rv

        protocol     = "$r->{'_protocol'}"
        status       = "$r->{'_status'}"
        message      = "$r->{'_message'}"

        keepalive    = $r->{'_keepalive'}
        
        END
    }


};
