#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use HTTP::Headers;

BEGIN {
    use_ok('HTTP::Headers::ActionPack::DateHeader');
    use_ok('HTTP::Headers::ActionPack::LinkHeader');
    use_ok('HTTP::Headers::ActionPack::LinkList');
    use_ok('HTTP::Headers::ActionPack::MediaType');
}

=pod

This just tests that HTTP::Headers does
not stringify our objects until we ask
it to.

=cut


{
    my $h = HTTP::Headers->new(
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
    );

    isa_ok($h->header('Date'), 'HTTP::Headers::ActionPack::DateHeader', '... object is preserved and');
    isa_ok($h->header('Content-Type'), 'HTTP::Headers::ActionPack::MediaType', '... object is preserved and');
    isa_ok($h->header('Link'), 'HTTP::Headers::ActionPack::LinkList', '... object is preserved and');

    is(
        $h->as_string,
    q{Date: Mon, 23 Apr 2012 14:14:19 GMT
Content-Type: application/xml; charset="UTF-8"
Link: <http://example.com/TheBook/chapter2>; rel="previous"; title="previous chapter"
},
        '... got the stringified headers'
    );
}

done_testing;