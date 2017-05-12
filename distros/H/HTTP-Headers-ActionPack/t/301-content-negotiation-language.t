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

# From http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html

is(
    $n->choose_language( ['da', 'en-US', 'es'], "da, en-gb;q=0.8, en;q=0.7" ),
    'da',
    '... got the right language back'
);

is(
    $n->choose_language( ['en-US', 'es'], "da, en-gb;q=0.8, en;q=0.7" ),
    'en-US',
    '... got the right language back'
);

is(
    $n->choose_language( ['en-gb', 'da'], "da, en-gb;q=0.8, en;q=0.7" ),
    'da',
    '... got the right language back'
);

is(
    $n->choose_language( ['en-US', 'en-GB'], "da, en-gb;q=0.8, en;q=0.7" ),
    'en-GB',
    '... got the right language back'
);

is(
    $n->choose_language( ['en-us'], "da, en-US;q=0.8, en;q=0.7" ),
    'en-us',
    '... languages in choices list are canonicalized'
);

is(
    $n->choose_language( ['en-US'], "da, en-us;q=0.8, en;q=0.7" ),
    'en-US',
    '... languages in header are canonicalized'
);

# From webmachine-ruby

is($n->choose_language( [], 'en' ), undef, '... got nothing back');
is($n->choose_language( ['en'], 'es' ), undef, '... got nothing back');

is(
    $n->choose_language( ['en', 'en-US', 'es'], "en-US, es" ),
    'en-US',
    '... got the right language back'
);

is(
    $n->choose_language( ['en', 'en-US', 'es'], "en-US;q=0.6, es" ),
    'es',
    '... got the right language back'
);

is(
    $n->choose_language( ['en', 'fr', 'es'], "*" ),
    'en',
    '... got the right language back'
);

is(
    $n->choose_language( ['en-US', 'es'], "en, fr" ),
    'en-US',
    '... got the right language back'
);

is(
    $n->choose_language( [ 'en-US', 'ZH' ], "zh-ch, EN" ),
    'en-US',
    '... got the right language back'
);



done_testing;
