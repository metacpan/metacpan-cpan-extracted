# Copyright (C) 2004  Joshua Hoblitt
#
# $Id: 03_join.t,v 1.2 2004/07/18 19:36:35 jhoblitt Exp $

use strict;
use warnings;
 
use Test::More;

require HTTP::Range;
require HTTP::Response;
require HTTP::Headers;
use HTTP::Status qw( RC_OK RC_NOT_FOUND );

use vars qw( @responses $header );

eval "use Storable qw( dclone )";
if ( $@ ) {
    plan skip_all => "Storable >= 2.0 not installed";
} else {
    plan tests => 27;
}

{
    $header = HTTP::Headers->new;
    $header->header( 'Content-Type' => 'text/plain' );
    $header->header( 'Content-Length' => 3 );

    my $h = dclone( $header );

    $h->header( 'Content-Range' => 'bytes 0-2' );
    push( @responses, HTTP::Response->new( 206, "Partial Content", $h,  "111" ) );
    $h->header( 'Content-Range' => 'bytes 3-5' );
    push( @responses, HTTP::Response->new( 206, "Partial Content", $h,  "222" ) );
    $h->header( 'Content-Range' => 'bytes 6-8' );
    push( @responses, HTTP::Response->new( 206, "Partial Content", $h,  "333" ) );
    $h->header( 'Content-Range' => 'bytes 9-11');
    push( @responses, HTTP::Response->new( 206, "Partial Content", $h,  "444" ) );
}

{
    my $res = HTTP::Range->join(
            responses   => dclone( \@responses ),
        );
    isa_ok( $res, "HTTP::Response" );
    is( $res->code, RC_OK );
    is( $res->message, HTTP::Status::status_message( RC_OK ) );
    is( $res->content, "111222333444" );
    is( $res->content_length, 12 );
}

{
    my $res = HTTP::Range->join(
            responses   => dclone( \@responses ),
            length      => 12,
        );
    isa_ok( $res, "HTTP::Response" );
    is( $res->code, RC_OK );
    is( $res->message, HTTP::Status::status_message( RC_OK ) );
    is( $res->content, "111222333444" );
    is( $res->content_length, 12 );
}

eval {
    my @req = HTTP::Range->join();
};
like( $@, qr/Mandatory parameter/ );

eval {
    my $foo;

    my @req = HTTP::Range->join(
            responses   => $foo
       );
};
like( $@, qr/not one of the allowed types/ );

eval {
    my @req = HTTP::Range->join(
            responses   => dclone( \@responses ),
            length      => 0,
       );
};
like( $@, qr/length is > 0/ );

eval {
    my @req = HTTP::Range->join(
            responses   => dclone( \@responses ),
            length      => 1.5,
       );
};
like( $@, qr/length is \+ integer/ );

eval {
    my @req = HTTP::Range->join(
            responses   => dclone( \@responses ),
            length      => -1,
       );
};
like( $@, qr/length is \+ integer/ );

eval {
    my $h = dclone( $header );

    my @req = HTTP::Range->join(
            responses   => [
                HTTP::Response->new( 206, "Partial Content", $h, "42" ),
            ],
            segments    => 1,
       );
};
like( $@, qr/segments is > 1/ );

eval {
    my @req = HTTP::Range->join(
            responses   => dclone( \@responses ),
            segments    => 1.5,
       );
};
like( $@, qr/segments is \+ integer/ );

eval {
    my @req = HTTP::Range->join(
            responses   => dclone( \@responses ),
            segments    => -1,
       );
};
like( $@, qr/segments is \+ integer/ );

eval {
    my $h = dclone( $header );

    my @req = HTTP::Range->join(
            responses   => [
                HTTP::Response->new( 206, "Partial Content", $h, "42" ),
                HTTP::Response->new( 206, "Partial Content", $h, "42" ),
            ],
            length      => 1,
            segments    => 2,
       );
};
like( $@, qr/segments is <= length/ );

eval {
    my @req = HTTP::Range->join(
            responses   => dclone( \@responses ),
            segments    => 2,
       );
};
like( $@, qr/segments is == responses/ );

eval {
    my $res_ref = dclone( \@responses );
    push( @$res_ref, HTTP::Headers->new );

    my @req = HTTP::Range->join(
            responses   => $res_ref
       );
};
like( $@, qr/not isa HTTP::Response/ );

eval {
    my $res_ref = dclone( \@responses );
    push( @$res_ref, HTTP::Response->new( RC_NOT_FOUND ) );

    my @req = HTTP::Range->join(
            responses   => $res_ref,
       );
};
like( $@, qr/not a successful HTTP status/ );

eval {
    my $res_ref = dclone( \@responses );
    my $h = dclone( $header );

    my $res = HTTP::Response->new( 206, "Partial Content", $h,  "111" );
    $res->add_part( HTTP::Message->new );
    push( @$res_ref, $res );

    my @req = HTTP::Range->join(
            responses   => $res_ref,
       );
};
like( $@, qr/multi-part messages are not supported/ );

eval {
    my $res_ref = dclone( \@responses );
    my $h = dclone( $header );

    $h->header( 'Content-Range' => 'bytes 0-2' );
    push( @$res_ref, HTTP::Response->new( 206, "Partial Content", $h,  "111" ) );
    $h->header( 'Content-Range' => 'bytes 3-5' );
    push( @$res_ref, HTTP::Response->new( 206, "Partial Content", $h,  "22" ) );

    my @req = HTTP::Range->join(
            responses   => $res_ref,
       );
};
like( $@, qr/segment has invalid content length/ );

eval {
    my $res_ref = dclone( \@responses );
    my $h = dclone( $header );

    $h->header( 'Content-Range' => 'bytes 0-2' );
    push( @$res_ref, HTTP::Response->new( 206, "Partial Content", $h,  "111" ) );
    $h->header( 'Content-Range' => 'bytes 3-5' );
    push( @$res_ref, HTTP::Response->new( 206, "Partial Content", $h,  "222" ) );

    my @req = HTTP::Range->join(
            responses   => $res_ref,
            length      => 7,
       );
};
like( $@, qr/specified content length does not equal received content length/ );

eval {
    my @responses;
    my $h = dclone( $header );

    $h->header( 'Content-Length' => 3 );
    $h->header( 'Content-Range' => 'bytes 0-2' );
    push( @responses, HTTP::Response->new( 206, "Partial Content", $h,  "111" ) );
    $h->header( 'Content-Range' => 'bytes 0-2' );
    push( @responses, HTTP::Response->new( 206, "Partial Content", $h,  "222" ) );

    my @req = HTTP::Range->join(
            responses   => \@responses,
       );
};
like( $@, qr/segments overlap/ );

eval {
    my @responses;
    my $h = dclone( $header );

    $h->header( 'Content-Length' => 3 );
    $h->header( 'Content-Range' => 'bytes 0-2' );
    push( @responses, HTTP::Response->new( 206, "Partial Content", $h,  "111" ) );
    $h->header( 'Content-Range' => 'bytes 4-6' );
    push( @responses, HTTP::Response->new( 206, "Partial Content", $h,  "222" ) );

    my @req = HTTP::Range->join(
            responses   => \@responses,
            length      => 7,
       );
};
like( $@, qr/missing or incomplete segments/ );
