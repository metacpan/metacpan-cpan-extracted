# Copyright (C) 2004  Joshua Hoblitt
#
# $Id: 02_split.t,v 1.2 2004/07/18 19:36:35 jhoblitt Exp $

use strict;
use warnings;
  
use Test::More tests => 30;

require 
require HTTP::Range;
require HTTP::Request;
require HTTP::Headers;

{
    my @req = HTTP::Range->split(
            request     => HTTP::Request->new( GET => "http://example.com/" ),
            length      => 999,
        );

    is( $req[0]->method, "GET" );
    is( $req[0]->uri, "http://example.com/" );
    is( $req[0]->header( 'Range' ), "bytes=0-249" );

    is( $req[1]->method, "GET" );
    is( $req[1]->uri, "http://example.com/" );
    is( $req[1]->header( 'Range' ), "bytes=250-499" );

    is( $req[2]->method, "GET" );
    is( $req[2]->uri, "http://example.com/" );
    is( $req[2]->header( 'Range' ), "bytes=500-749" );

    is( $req[3]->method, "GET" );
    is( $req[3]->uri, "http://example.com/" );
    is( $req[3]->header( 'Range' ), "bytes=750-998" );
}

{
    my @req = HTTP::Range->split(
            request     => HTTP::Request->new( GET => "http://example.com/" ),
            length      => 999,
            segments    => 2,
        );

    is( $req[0]->method, "GET" );
    is( $req[0]->uri, "http://example.com/" );
    is( $req[0]->header( 'Range' ), "bytes=0-499" );

    is( $req[1]->method, "GET" );
    is( $req[1]->uri, "http://example.com/" );
    is( $req[1]->header( 'Range' ), "bytes=500-998" );
}

{
    my @req = HTTP::Range->split(
            request     => HTTP::Request->new( GET => "http://example.com/" ),
            length      => 2,
            segments    => 2,
        );

    is( @req, 2 );
}

eval {
    my @req = HTTP::Range->split();
};
like( $@, qr/Mandatory parameter/ );

eval {
    my @req = HTTP::Range->split(
            request     => HTTP::Request->new( GET => "http://example.com/" ),
        );
};
like( $@, qr/Mandatory parameter/ );

eval {
    my @req = HTTP::Range->split(
            length      => 42,
        );
};
like( $@, qr/Mandatory parameter/ );

eval {
    my @req = HTTP::Range->split(
            request     => HTTP::Headers->new,
            length      => 1,
        );
};
like( $@, qr/not a 'HTTP::Request'/ );

eval {
    my @req = HTTP::Range->split(
            request     => HTTP::Request->new( GET => "http://example.com/" ),
            length      => 0,
        );
};
like( $@, qr/length is > 0/ );

eval {
    my @req = HTTP::Range->split(
            request     => HTTP::Request->new( GET => "http://example.com/" ),
            length      => 1.5,
        );
};
like( $@, qr/length is \+ integer/ );

eval {
    my @req = HTTP::Range->split(
            request     => HTTP::Request->new( GET => "http://example.com/" ),
            length      => -1,
        );
};
like( $@, qr/length is \+ integer/ );

eval {
    my @req = HTTP::Range->split(
            request     => HTTP::Request->new( GET => "http://example.com/" ),
            length      => 42,
            segments    => 1,
        );
};
like( $@, qr/segments is > 1/ );

eval {
    my @req = HTTP::Range->split(
            request     => HTTP::Request->new( GET => "http://example.com/" ),
            length      => 42,
            segments    => 1.5,
        );
};
like( $@, qr/segments is \+ integer/ );

eval {
    my @req = HTTP::Range->split(
            request     => HTTP::Request->new( GET => "http://example.com/" ),
            length      => 42,
            segments    => -1,
        );
};
like( $@, qr/segments is \+ integer/ );

eval {
    my @req = HTTP::Range->split(
            request     => HTTP::Request->new( GET => "http://example.com/" ),
            length      => 1,
            segments    => 2,
        );
};
like( $@, qr/segments is <= length/ );
