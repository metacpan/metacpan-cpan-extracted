#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use HTTP::Request;
use HTTP::Response;
use HTTP::Headers;
use Module::Runtime qw[ use_module ];

=pod

This just tests that HTTP::Message::PSGI,
Plack::Request and Plack::Response do not
stringify our objects.

=cut
BEGIN {
    unless ( eval { use_module('HTTP::Message::PSGI') && use_module('Plack::Request') && use_module('Plack::Response') } ) {
        plan skip_all => "Must have HTTP::Message::PSGI, Plack::Request and Plack::Response";
    }
}

BEGIN {
    use_ok('HTTP::Headers::ActionPack');
    use_ok('HTTP::Headers::ActionPack::DateHeader');
    use_ok('HTTP::Headers::ActionPack::LinkHeader');
    use_ok('HTTP::Headers::ActionPack::LinkList');
    use_ok('HTTP::Headers::ActionPack::MediaType');
}

{
    my $r = HTTP::Request->new(
        'GET',
        '/foo',
        [
            Date         => HTTP::Headers::ActionPack::DateHeader->new_from_string('Mon, 23 Apr 2012 14:14:19 GMT'),
            Content_Type => HTTP::Headers::ActionPack::MediaType->new('application/xml', 'charset' => 'UTF-8'),
            Link         => HTTP::Headers::ActionPack::LinkList->new(
                HTTP::Headers::ActionPack::LinkHeader->new(
                    'http://example.com/TheBook/chapter2' => (
                        rel   => "previous",
                        title => "previous chapter"
                    )
                )
            )
        ]
    );

    my $env = $r->to_psgi;

    isa_ok($env->{'HTTP_DATE'}, 'HTTP::Headers::ActionPack::DateHeader', '... object is preserved and');
    isa_ok($env->{'CONTENT_TYPE'}, 'HTTP::Headers::ActionPack::MediaType', '... object is preserved and');
    isa_ok($env->{'HTTP_LINK'}, 'HTTP::Headers::ActionPack::LinkList', '... object is preserved and');

    my $plack_r = Plack::Request->new( $env );

    isa_ok($plack_r->header('Date'), 'HTTP::Headers::ActionPack::DateHeader', '... object is preserved and');
    isa_ok($plack_r->header('Content-Type'), 'HTTP::Headers::ActionPack::MediaType', '... object is preserved and');
    isa_ok($plack_r->header('Link'), 'HTTP::Headers::ActionPack::LinkList', '... object is preserved and');
}

{
    my $r = [
        200,
        [
            Date         => HTTP::Headers::ActionPack::DateHeader->new_from_string('Mon, 23 Apr 2012 14:14:19 GMT'),
            Content_Type => HTTP::Headers::ActionPack::MediaType->new('application/xml', 'charset' => 'UTF-8'),
            Link         => HTTP::Headers::ActionPack::LinkList->new(
                HTTP::Headers::ActionPack::LinkHeader->new(
                    'http://example.com/TheBook/chapter2' => (
                        rel   => "previous",
                        title => "previous chapter"
                    )
                )
            )
        ],
        []
    ];

    my $http_r = HTTP::Response->from_psgi( $r );

    isa_ok($http_r->header('Date'), 'HTTP::Headers::ActionPack::DateHeader', '... object is preserved and');
    isa_ok($http_r->header('Content-Type'), 'HTTP::Headers::ActionPack::MediaType', '... object is preserved and');
    isa_ok($http_r->header('Link'), 'HTTP::Headers::ActionPack::LinkList', '... object is preserved and');

    is(
        $http_r->as_string,
    q{200 OK
Date: Mon, 23 Apr 2012 14:14:19 GMT
Content-Type: application/xml; charset="UTF-8"
Link: <http://example.com/TheBook/chapter2>; rel="previous"; title="previous chapter"

},
        '... got the stringified headers'
    );

    my $plack_r = Plack::Response->new( @$r );

    isa_ok($plack_r->header('Date'), 'HTTP::Headers::ActionPack::DateHeader', '... object is preserved and');
    isa_ok($plack_r->header('Content-Type'), 'HTTP::Headers::ActionPack::MediaType', '... object is preserved and');
    isa_ok($plack_r->header('Link'), 'HTTP::Headers::ActionPack::LinkList', '... object is preserved and');
}

{
    my $r = HTTP::Request->new(
        'GET',
        '/foo',
        [
            Date         => 'Mon, 23 Apr 2012 14:14:19 GMT',
            Content_Type => 'application/xml; charset=UTF-8',
            Link         => '<http://example.com/TheBook/chapter2>; rel=previous; title="previous chapter"'
        ]
    );

    my $plack_r = Plack::Request->new( $r->to_psgi );

    HTTP::Headers::ActionPack->new->inflate( $plack_r );

    isa_ok($plack_r->header('Date'), 'HTTP::Headers::ActionPack::DateHeader', '... object is inflated and');
    isa_ok($plack_r->header('Content-Type'), 'HTTP::Headers::ActionPack::MediaType', '... object is inflated and');
    isa_ok($plack_r->header('Link'), 'HTTP::Headers::ActionPack::LinkList', '... object is inflated and');

    is($plack_r->env->{'HTTP_DATE'}, 'Mon, 23 Apr 2012 14:14:19 GMT', '... the underlying env is preserved');
    is($plack_r->env->{'CONTENT_TYPE'}, 'application/xml; charset=UTF-8', '... the underlying env is preserved');
    is($plack_r->env->{'HTTP_LINK'}, '<http://example.com/TheBook/chapter2>; rel=previous; title="previous chapter"', '... the underlying env is preserved');

}



done_testing;
