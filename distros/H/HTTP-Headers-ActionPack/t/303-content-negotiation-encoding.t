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

is($n->choose_encoding( [], 'identity, gzip' ), undef, '... got nothing back (encoding short circuited)');
is($n->choose_encoding( [ "gzip" ], 'identity' ), undef, '... got nothing back (encoding short circuited)');

is(
    $n->choose_encoding( [ "gzip", "identity" ], "identity" ),
    'identity',
    '... got the right encoding back'
);

is(
    $n->choose_encoding( [ "gzip" ], "identity, gzip" ),
    'gzip',
    '... got the right encoding back'
);

is(
    $n->choose_encoding( [ "gzip", "identity" ], "gzip, identity;q=0.7" ),
    'gzip',
    '... got the right encoding back'
);


done_testing;