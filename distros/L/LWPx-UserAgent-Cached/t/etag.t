#!/usr/bin/env perl

use strict;
use warnings;
use English '-no_match_vars';
use Digest::SHA;
use HTTP::Status qw(HTTP_OK HTTP_NOT_MODIFIED);
use Test::More;
use Test::Fake::HTTPD;
use LWPx::UserAgent::Cached;

my $CONTENT = 'Hello world!';
my $ETAG    = Digest::SHA->new(256)->add($CONTENT)->hexdigest;

my $httpd = Test::Fake::HTTPD->new( $PERLDB ? ( timeout => undef ) : () );

$httpd->run(
    sub {
        my $request = shift;
        return [ HTTP_NOT_MODIFIED, [], [] ]
            if $request->header('if_none_match')
            and $request->header('if_none_match') eq $ETAG;
        return [
            HTTP_OK,
            [   'Content-Type' => 'text/plain',
                'ETag'         => $ETAG,
            ],
            [$CONTENT],
        ];
    },
);

my $user_agent = LWPx::UserAgent::Cached->new;
is( $user_agent->is_cached, undef, 'start undef cache' );

note "Response:\n" => $user_agent->get( $httpd->endpoint )->dump;
is( $user_agent->is_cached, 0, 'still uncached' );

my $response = $user_agent->get( $httpd->endpoint );
note "Response:\n" => $response->dump;
is( $user_agent->is_cached, 1,                 'now cached' );
is( $response->code,        HTTP_NOT_MODIFIED, 'got HTTP 304' );
is( $response->content,     $CONTENT,          'got content' );

done_testing;
