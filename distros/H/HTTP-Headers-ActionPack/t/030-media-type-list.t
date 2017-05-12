#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTTP::Headers::ActionPack::MediaTypeList');
}

{
    my $list = HTTP::Headers::ActionPack::MediaTypeList->new(
        HTTP::Headers::ActionPack::MediaType->new('audio/*', q => 0.2 ),
        HTTP::Headers::ActionPack::MediaType->new('audio/basic', q => 1.0 )
    );
    isa_ok($list, 'HTTP::Headers::ActionPack::MediaTypeList');

    is(
        $list->as_string,
        'audio/basic; q="1", audio/*; q="0.2"',
        '... got the expected string back'
    );
}

{
    my $list = HTTP::Headers::ActionPack::MediaTypeList->new(
        [ 0.2 => HTTP::Headers::ActionPack::MediaType->new('audio/*', q => 0.2 )     ],
        [ 1.0 => HTTP::Headers::ActionPack::MediaType->new('audio/basic' ) ]
    );
    isa_ok($list, 'HTTP::Headers::ActionPack::MediaTypeList');

    is(
        $list->as_string,
        'audio/basic, audio/*; q="0.2"',
        '... got the expected string back'
    );
}

{
    my $list = HTTP::Headers::ActionPack::MediaTypeList->new_from_string(
        'audio/*; q=0.2, audio/basic'
    );
    isa_ok($list, 'HTTP::Headers::ActionPack::MediaTypeList');

    is(
        $list->as_string,
        'audio/basic, audio/*; q="0.2"',
        '... got the expected string back'
    );
}

{
    my $list = HTTP::Headers::ActionPack::MediaTypeList->new_from_string(
        'text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c'
    );
    isa_ok($list, 'HTTP::Headers::ActionPack::MediaTypeList');

    is(
        $list->as_string,
        'text/html, text/x-c, text/x-dvi; q="0.8", text/plain; q="0.5"',
        '... got the expected string back'
    );
}

{
    my $list = HTTP::Headers::ActionPack::MediaTypeList->new_from_string(
        'text/*, text/html, text/html;level=1, */*'
    );
    isa_ok($list, 'HTTP::Headers::ActionPack::MediaTypeList');

    is(
        $list->as_string,
        'text/html; level="1", text/html, text/*, */*',
        '... got the expected string back'
    );
}

{
    my $list = HTTP::Headers::ActionPack::MediaTypeList->new_from_string(
        'text/html;charset=iso8859-1, application/xml'
    );
    isa_ok($list, 'HTTP::Headers::ActionPack::MediaTypeList');

    is(
        $list->as_string,
        'text/html; charset="iso8859-1", application/xml',
        '... got the expected string back'
    );
}

{
    my $list = HTTP::Headers::ActionPack::MediaTypeList->new_from_string(
        'application/xml;q=0.7, text/html, */*'
    );
    isa_ok($list, 'HTTP::Headers::ActionPack::MediaTypeList');

    is(
        $list->as_string,
        'text/html, */*, application/xml; q="0.7"',
        '... got the expected string back'
    );
}

{
    my $list = HTTP::Headers::ActionPack::MediaTypeList->new_from_string(
        'application/json;v=3;foo=bar, application/json;v=2'
    );
    isa_ok($list, 'HTTP::Headers::ActionPack::MediaTypeList');

    is(
        $list->as_string,
        'application/json; v="2", application/json; v="3"; foo="bar"',
        '... got the expected string back'
    );
}


done_testing;