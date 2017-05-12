#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use HTTP::Request;
use Module::Runtime 'use_module';

use HTTP::Headers::ActionPack;

my $has_plack = eval {
    use_module('HTTP::Message::PSGI');
    use_module('Plack::Request');
    1;
};

my $has_web_request = eval {
    use_module('Web::Request');
    1;
};

my $pack = HTTP::Headers::ActionPack->new;

{
    my $h = HTTP::Headers->new(
        Date         => 'Mon, 23 Apr 2012 14:14:19 GMT',
        Content_Type => 'application/xml; charset=UTF-8',
        Link         => '<http://example.com/TheBook/chapter2>; rel=previous; title="previous chapter"'
    );

    {
        my $r = HTTP::Request->new('GET', '/foo', $h->clone);
        $pack->inflate($r);

        my $date = $r->headers->header('date');
        isa_ok($date, 'HTTP::Headers::ActionPack::DateHeader');
        is($date->as_string, 'Mon, 23 Apr 2012 14:14:19 GMT');

        my $content_type = $r->headers->header('content-type');
        isa_ok($content_type, 'HTTP::Headers::ActionPack::MediaType');
        like($content_type->as_string, qr{application/xml.*UTF-8});

        my $link = $r->headers->header('link');
        isa_ok($link, 'HTTP::Headers::ActionPack::LinkList');
        like($link->as_string, qr{http://example\.com/TheBook/chapter2.*previous.*previous chapter});
    }

    SKIP: {
        skip "Plack::Request and HTTP::Message::PSGI are required", 6
            unless $has_plack;
        my $http_request = HTTP::Request->new('GET', '/foo', $h->clone);
        my $r = Plack::Request->new($http_request->to_psgi);
        $pack->inflate($r);

        my $date = $r->headers->header('date');
        isa_ok($date, 'HTTP::Headers::ActionPack::DateHeader');
        is($date->as_string, 'Mon, 23 Apr 2012 14:14:19 GMT');

        my $content_type = $r->headers->header('content-type');
        isa_ok($content_type, 'HTTP::Headers::ActionPack::MediaType');
        like($content_type->as_string, qr{application/xml.*UTF-8});

        my $link = $r->headers->header('link');
        isa_ok($link, 'HTTP::Headers::ActionPack::LinkList');
        like($link->as_string, qr{http://example\.com/TheBook/chapter2.*previous.*previous chapter});
    }

    SKIP: {
        skip "Web::Request is required", 6
            unless $has_plack && $has_web_request;
        my $http_request = HTTP::Request->new('GET', '/foo', $h->clone);
        my $r = Web::Request->new_from_env($http_request->to_psgi);
        $pack->inflate($r);

        my $date = $r->headers->header('date');
        isa_ok($date, 'HTTP::Headers::ActionPack::DateHeader');
        is($date->as_string, 'Mon, 23 Apr 2012 14:14:19 GMT');

        my $content_type = $r->headers->header('content-type');
        isa_ok($content_type, 'HTTP::Headers::ActionPack::MediaType');
        like($content_type->as_string, qr{application/xml.*UTF-8});

        my $link = $r->headers->header('link');
        isa_ok($link, 'HTTP::Headers::ActionPack::LinkList');
        like($link->as_string, qr{http://example\.com/TheBook/chapter2.*previous.*previous chapter});
    }
}

done_testing;
