#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTTP::Headers::ActionPack');
}

my $n = HTTP::Headers::ActionPack->new->get_content_negotiator;
isa_ok($n, 'HTTP::Headers::ActionPack::ContentNegotiation');

is(
    $n->choose_media_type( [], '*/*' ),
    undef,
    '... got nothing back (no choices)'
);
is(
    $n->choose_media_type( ["text/html"], 'application/json' ),
    undef,
    '... got nothing back (no matches)'
);

# Examples from http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html

=pod

The example

       Accept: audio/*; q=0.2, audio/basic

SHOULD be interpreted as "I prefer audio/basic, but send me any
audio type if it is the best available after an 80% mark-down
in quality."

=cut


is(
    $n->choose_media_type(
        ["audio/basic", "audio/oog"],
        "audio/*; q=0.2, audio/basic"
    ),
    'audio/basic',
    '... got the right media type back (prefer audio/basic)'
);

isa_ok(
    $n->choose_media_type(
        ["audio/basic", "audio/oog"],
        "audio/*; q=0.2, audio/basic"
    ),
    'HTTP::Headers::ActionPack::MediaType',
    '... got back the object actually ->'
);

is(
    $n->choose_media_type(
        ["audio/mp3", "audio/oog"],
        "audio/*; q=0.2, audio/basic"
    ),
    'audio/mp3',
    '... got the right media type back (prefer audio/* and choose audio/mp3)'
);

=pod

A more elaborate example is

       Accept: text/plain; q=0.5, text/html,
               text/x-dvi; q=0.8, text/x-c

Verbally, this would be interpreted as "text/html and text/x-c
are the preferred media types, but if they do not exist, then
send the text/x-dvi entity, and if that does not exist, send
the text/plain entity."

=cut

is(
    $n->choose_media_type(
        ["text/html", "text/plain"],
        "text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c"
    ),
    'text/html',
    '... got the right media type back (prefer text/html over lesser quality options)'
);

is(
    $n->choose_media_type(
        ["text/html", "text/x-dvi"],
        "text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c"
    ),
    'text/html',
    '... got the right media type back (prefer text/html over lesser quality options)'
);

is(
    $n->choose_media_type(
        ["text/x-c", "text/plain"],
        "text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c"
    ),
    'text/x-c',
    '... got the right media type back (prefer text/x-c over lesser quality options)'
);

is(
    $n->choose_media_type(
        ["text/x-c", "text/x-dvi"],
        "text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c"
    ),
    'text/x-c',
    '... got the right media type back (prefer text/x-c over lesser quality options)'
);

is(
    $n->choose_media_type(
        ["text/x-c", "text/html"],
        "text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c"
    ),
    'text/html',
    '... got the right media type back (prefer text/html over text/x-c)'
);

is(
    $n->choose_media_type(
        ["text/sgml", "text/x-dvi"],
        "text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c"
    ),
    'text/x-dvi',
    '... got the right media type back (accept text/x-dvi)'
);

is(
    $n->choose_media_type(
        ["text/sgml", "text/plain", "text/x-dvi"],
        "text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c"
    ),
    'text/x-dvi',
    '... got the right media type back (prefer text/x-dvi over text/plain)'
);

is(
    $n->choose_media_type(
        ["text/sgml", "text/plain", ],
        "text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c"
    ),
    'text/plain',
    '... got the right media type back (accept text/plain)'
);

=pod

Media ranges can be overridden by more specific media ranges
or specific media types. If more than one media range applies
to a given type, the most specific reference has precedence.
For example,

       Accept: text/*, text/html, text/html;level=1, */*

have the following precedence:

       1) text/html;level=1
       2) text/html
       3) text/*
       4) */*

=cut

is(
    $n->choose_media_type(
        ["text/html", "text/html;level=1" ],
        "text/*, text/html, text/html;level=1, */*"
    ),
    'text/html; level="1"',
    '... got the right media type back (prefer text/html;level=1 because it is more specific)'
);

is(
    $n->choose_media_type(
        ["text/plain", "text/html" ],
        "text/*, text/html, text/html;level=1, */*"
    ),
    'text/html',
    '... got the right media type back (prefer text/html to other less specific options)'
);

# Examples from webmachine-ruby

is(
    $n->choose_media_type(
        ["text/html", "application/xml"],
        "application/xml, text/html, */*"
    ),
    'application/xml',
    '... got the right media type back (choose application/xml because of header ordering)'
);

is(
    $n->choose_media_type(
        ["text/html", "text/html;charset=iso8859-1" ],
        "text/html;charset=iso8859-1, application/xml"
    ),
    'text/html; charset="iso8859-1"',
    '... got the right media type back (choose the more specific text/html;charset=iso8859-1)'
);

is(
    $n->choose_media_type(
        ["application/json;v=3;foo=bar", "application/json;v=2"],
        "text/html, application/json"
    ),
    'application/json; v="3"; foo="bar"',
    '... got the right media type back (choose application/json;v=3;foo=bar because of preference ordering)'
);

is(
    $n->choose_media_type(
        ["text/html", "application/xml"],
        "application/xml;q=0.7, text/html, */*"
    ),
    'text/html',
    '... got the right media type back (choose text/html because of quality level and preference ordering)'
);

is(
    $n->choose_media_type(
        ["text/html", "application/xml"],
        "bah"
    ),
    undef,
    '... got no media type back'
);


done_testing;
