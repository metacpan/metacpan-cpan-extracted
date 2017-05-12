#!/usr/bin/env perl

use strict;
use warnings;
use English '-no_match_vars';
use HTTP::Status qw(HTTP_OK HTTP_NOT_MODIFIED);
use Test::More tests => 2;
use Test::Fake::HTTPD;
use LWPx::UserAgent::Cached;

subtest request => sub {
    my $httpd = Test::Fake::HTTPD->new( $PERLDB ? ( timeout => undef ) : () );
    $httpd->run(
        sub {
            [ HTTP_OK, [ 'Content-Type' => 'text/plain' ], ['Hello world!'] ];
        },
    );

    my @headers = (
        { 'Cache-Control' => 'no-cache' },
        { 'Cache-Control' => 'no-store' },
        { 'Pragma'        => 'no-cache' },
    );
    plan tests => scalar @headers;

    for my $headers_ref (@headers) {
        my $user_agent = LWPx::UserAgent::Cached->new;
        note "Response:\n" =>
            $user_agent->get( $httpd->endpoint, %{$headers_ref} )->dump;

        my $response = $user_agent->get( $httpd->endpoint, %{$headers_ref} );
        note "Request:\n" => $response->request->dump;
        is( $user_agent->is_cached, 0, 'still uncached' );
    }
};

subtest response => sub {
    my @headers = (
        { 'Cache-Control' => 'no-cache' },
        { 'Cache-Control' => 'no-store' },
    );
    plan tests => scalar @headers;

    for my $headers_ref (@headers) {
        my $httpd
            = Test::Fake::HTTPD->new( $PERLDB ? ( timeout => undef ) : () );
        $httpd->run(
            sub {
                [   HTTP_OK,
                    [ 'Content-Type' => 'text/plain', %{$headers_ref} ],
                    ['Hello world!'],
                ];
            },
        );

        my $user_agent = LWPx::UserAgent::Cached->new;
        note "Response:\n" => $user_agent->get( $httpd->endpoint )->dump;

        my $response = $user_agent->get( $httpd->endpoint );
        note "Request:\n" => $response->request->dump;
        is( $user_agent->is_cached, 0, 'still uncached' );
    }
};
