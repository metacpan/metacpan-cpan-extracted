#!perl

use strict;
use warnings;

use Test2::V0;

use HTTP::libsfparse qw( parse_item :types );

is parse_item('foo'),
    [ SFPARSE_TYPE_TOKEN, 'foo', [] ],
    'a bare token';

is parse_item('text/html;q=0.8'),
    [
        SFPARSE_TYPE_TOKEN,
        'text/html',
        [ [ 'q', [ SFPARSE_TYPE_DECIMAL, 0.8, undef ] ] ],
    ],
    'a token with a decimal parameter';

is parse_item('  foo  '),
    [ SFPARSE_TYPE_TOKEN, 'foo', [] ],
    'surrounding spaces are allowed';

# Every item is three elements wide whatever its type, so that indexing into
# one never has to look at the type first.

for my $field ( 'foo', '?1', '42', '1.5', '"s"', ':aGk=:', '@0', '%"a"', '()' )
{
    my $item = parse_item($field);

    is scalar @$item, 3, "an item is three elements wide: '$field'";
}

# Inner lists are items too, and may be a whole field value.

is parse_item('()'),
    [ SFPARSE_TYPE_INNER_LIST, [], [] ],
    'an empty inner list';

is parse_item('(1 2)'),
    [
        SFPARSE_TYPE_INNER_LIST,
        [
            [ SFPARSE_TYPE_INTEGER, 1, [] ],
            [ SFPARSE_TYPE_INTEGER, 2, [] ],
        ],
        [],
    ],
    'an inner list of integers';

is parse_item('(1;a=1 2);b=2'),
    [
        SFPARSE_TYPE_INNER_LIST,
        [
            [
                SFPARSE_TYPE_INTEGER,
                1,
                [ [ 'a', [ SFPARSE_TYPE_INTEGER, 1, undef ] ] ],
            ],
            [ SFPARSE_TYPE_INTEGER, 2, [] ],
        ],
        [ [ 'b', [ SFPARSE_TYPE_INTEGER, 2, undef ] ] ],
    ],
    'parameters of an inner list and of its members are kept apart';

# A field value that is an item holds exactly one item.

for my $bad ( 'foo bar', 'foo, bar', '', '   ', 'a=1' ) {
    ok !eval { parse_item($bad); 1 }, "not a single item: '$bad'";
    like $@, qr/^HTTP::libsfparse: parse error at offset \d+/, '... parse error';
}

done_testing;
