#!perl

# Dictionaries and parameter lists come back as arrays of [ key, item ] pairs
# in field order, keeping duplicates. That is the only shape: there used to be
# an "ordered" option for it, and the hash form it switched away from, but a
# hash cannot hold a repeated key and the key order of one is not the field's.
# Rejecting a field value that repeats a key needs to see both occurrences.

use strict;
use warnings;

use Test2::V0;

use HTTP::libsfparse qw( parse_item parse_list parse_dictionary :types );

is parse_dictionary('a=1, b=2'),
    [
        [ 'a', [ SFPARSE_TYPE_INTEGER, 1, [] ] ],
        [ 'b', [ SFPARSE_TYPE_INTEGER, 2, [] ] ],
    ],
    'a dictionary is a list of pairs';

is [ map { $_->[0] } @{ parse_dictionary('b=1, a=2, c=3') } ],
    [ 'b', 'a', 'c' ],
    'field order is kept';

is [ map { $_->[0] } @{ parse_dictionary('a=1, b=2, a=3') } ],
    [ 'a', 'b', 'a' ],
    'duplicate keys are kept';

is parse_item('foo;a=1;a=2')->[2],
    [
        [ 'a', [ SFPARSE_TYPE_INTEGER, 1, undef ] ],
        [ 'a', [ SFPARSE_TYPE_INTEGER, 2, undef ] ],
    ],
    'parameters are pairs too, duplicates and all';

is parse_dictionary(''), [], 'an empty dictionary';
is parse_item('foo')->[2], [], 'an item with no parameters';

# Lists are already in order; their parameters take the same pair form.
is parse_list('a;x=1'),
    [
        [
            SFPARSE_TYPE_TOKEN,
            'a',
            [ [ 'x', [ SFPARSE_TYPE_INTEGER, 1, undef ] ] ],
        ],
    ],
    'list members carry pairs as well';

# Inner lists, their members and all their parameters follow suit.
is parse_item('(1;p=1 2);z=9'),
    [
        SFPARSE_TYPE_INNER_LIST,
        [
            [
                SFPARSE_TYPE_INTEGER,
                1,
                [ [ 'p', [ SFPARSE_TYPE_INTEGER, 1, undef ] ] ],
            ],
            [ SFPARSE_TYPE_INTEGER, 2, [] ],
        ],
        [ [ 'z', [ SFPARSE_TYPE_INTEGER, 9, undef ] ] ],
    ],
    'all the way down';

# The option is gone, rather than quietly ignored.
for my $parse ( \&parse_item, \&parse_list, \&parse_dictionary ) {
    ok !eval { $parse->( 'a', ordered => 1 ); 1 },
        'the parsers take no options';
    like $@, qr/^Usage: HTTP::libsfparse::parse_\w+\(input\)/, '... and say so';
}

done_testing;
